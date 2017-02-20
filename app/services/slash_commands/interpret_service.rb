module SlashCommands
  class InterpretService < BaseService
    include Gitlab::SlashCommands::Dsl

    attr_reader :issuable, :options

    # Takes a text and interprets the commands that are extracted from it.
    # Returns the content without commands, and hash of changes to be applied to a record.
    def execute(content, issuable)
      @issuable = issuable
      @updates = {}

      opts = {
        issuable:     issuable,
        current_user: current_user,
        project:      project,
        params:       params
      }

      content, commands = extractor.extract_commands(content, opts)

      commands.each do |name, arg|
        definition = self.class.command_definitions_by_name[name.to_sym]
        next unless definition

        definition.execute(self, opts, arg)
      end

      [content, @updates]
    end

    private

    def extractor
      Gitlab::SlashCommands::Extractor.new(self.class.command_definitions)
    end

    desc do
      "Close this #{issuable.to_ability_name.humanize(capitalize: false)}"
    end
    condition do
      issuable.persisted? &&
        issuable.open? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :close do
      @updates[:state_event] = 'close'
    end

    desc do
      "Reopen this #{issuable.to_ability_name.humanize(capitalize: false)}"
    end
    condition do
      issuable.persisted? &&
        issuable.closed? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :reopen do
      @updates[:state_event] = 'reopen'
    end

    desc 'Merge (when build succeeds)'
    condition do
      last_diff_sha = params && params[:merge_request_diff_head_sha]
      issuable.is_a?(MergeRequest) &&
        issuable.persisted? &&
        issuable.mergeable_with_slash_command?(current_user, autocomplete_precheck: !last_diff_sha, last_diff_sha: last_diff_sha)
    end
    command :merge do
      @updates[:merge] = params[:merge_request_diff_head_sha]
    end

    desc 'Change title'
    params '<New title>'
    condition do
      issuable.persisted? &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :title do |title_param|
      @updates[:title] = title_param
    end

    desc 'Assign'
    params '@user'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :assign do |assignee_param|
      user = extract_references(assignee_param, :user).first
      user ||= User.find_by(username: assignee_param)

      @updates[:assignee_id] = user.id if user
    end

    desc 'Remove assignee'
    condition do
      issuable.persisted? &&
        issuable.assignee_id? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :unassign do
      @updates[:assignee_id] = nil
    end

    desc 'Set milestone'
    params '%"milestone"'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project) &&
        project.milestones.active.any?
    end
    command :milestone do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      milestone ||= project.milestones.find_by(title: milestone_param.strip)

      @updates[:milestone_id] = milestone.id if milestone
    end

    desc 'Remove milestone'
    condition do
      issuable.persisted? &&
        issuable.milestone_id? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_milestone do
      @updates[:milestone_id] = nil
    end

    desc 'Add label(s)'
    params '~label1 ~"label 2"'
    condition do
      available_labels = LabelsFinder.new(current_user, project_id: project.id).execute

      current_user.can?(:"admin_#{issuable.to_ability_name}", project) &&
        available_labels.any?
    end
    command :label do |labels_param|
      label_ids = find_label_ids(labels_param)

      if label_ids.any?
        @updates[:add_label_ids] ||= []
        @updates[:add_label_ids] += label_ids

        @updates[:add_label_ids].uniq!
      end
    end

    desc 'Remove all or specific label(s)'
    params '~label1 ~"label 2"'
    condition do
      issuable.persisted? &&
        issuable.labels.any? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :unlabel do |labels_param = nil|
      if labels_param.present?
        label_ids = find_label_ids(labels_param)

        if label_ids.any?
          @updates[:remove_label_ids] ||= []
          @updates[:remove_label_ids] += label_ids

          @updates[:remove_label_ids].uniq!
        end
      else
        @updates[:label_ids] = []
      end
    end

    desc 'Replace all label(s)'
    params '~label1 ~"label 2"'
    condition do
      issuable.persisted? &&
        issuable.labels.any? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :relabel do |labels_param|
      label_ids = find_label_ids(labels_param)

      if label_ids.any?
        @updates[:label_ids] ||= []
        @updates[:label_ids] += label_ids

        @updates[:label_ids].uniq!
      end
    end

    desc 'Add a todo'
    condition do
      issuable.persisted? &&
        !TodoService.new.todo_exist?(issuable, current_user)
    end
    command :todo do
      @updates[:todo_event] = 'add'
    end

    desc 'Mark todo as done'
    condition do
      issuable.persisted? &&
        TodoService.new.todo_exist?(issuable, current_user)
    end
    command :done do
      @updates[:todo_event] = 'done'
    end

    desc 'Subscribe'
    condition do
      issuable.persisted? &&
        !issuable.subscribed?(current_user, project)
    end
    command :subscribe do
      @updates[:subscription_event] = 'subscribe'
    end

    desc 'Unsubscribe'
    condition do
      issuable.persisted? &&
        issuable.subscribed?(current_user, project)
    end
    command :unsubscribe do
      @updates[:subscription_event] = 'unsubscribe'
    end

    desc 'Set due date'
    params '<in 2 days | this Friday | December 31st>'
    condition do
      issuable.respond_to?(:due_date) &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :due do |due_date_param|
      due_date = Chronic.parse(due_date_param).try(:to_date)

      @updates[:due_date] = due_date if due_date
    end

    desc 'Remove due date'
    condition do
      issuable.persisted? &&
        issuable.respond_to?(:due_date) &&
        issuable.due_date? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_due_date do
      @updates[:due_date] = nil
    end

    desc do
      "Toggle the Work In Progress status"
    end
    condition do
      issuable.persisted? &&
        issuable.respond_to?(:work_in_progress?) &&
        current_user.can?(:"update_#{issuable.to_ability_name}", issuable)
    end
    command :wip do
      @updates[:wip_event] = issuable.work_in_progress? ? 'unwip' : 'wip'
    end

    desc 'Set time estimate'
    params '<1w 3d 2h 14m>'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :estimate do |raw_duration|
      time_estimate = Gitlab::TimeTrackingFormatter.parse(raw_duration)

      if time_estimate
        @updates[:time_estimate] = time_estimate
      end
    end

    desc 'Add or substract spent time'
    params '<1h 30m | -1h 30m>'
    condition do
      current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
    end
    command :spend do |raw_duration|
      time_spent = Gitlab::TimeTrackingFormatter.parse(raw_duration)

      if time_spent
        @updates[:spend_time] = { duration: time_spent, user: current_user }
      end
    end

    desc 'Remove time estimate'
    condition do
      issuable.persisted? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_estimate do
      @updates[:time_estimate] = 0
    end

    desc 'Remove spent time'
    condition do
      issuable.persisted? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", project)
    end
    command :remove_time_spent do
      @updates[:spend_time] = { duration: :reset, user: current_user }
    end

    # This is a dummy command, so that it appears in the autocomplete commands
    desc 'CC'
    params '@user'
    command :cc

    desc 'Defines target branch for MR'
    params '<Local branch name>'
    condition do
      issuable.respond_to?(:target_branch) &&
        (current_user.can?(:"update_#{issuable.to_ability_name}", issuable) ||
          issuable.new_record?)
    end
    command :target_branch do |target_branch_param|
      branch_name = target_branch_param.strip
      @updates[:target_branch] = branch_name if project.repository.branch_names.include?(branch_name)
    end

    desc 'Set weight'
    params Issue::WEIGHT_RANGE.to_s.squeeze('.').tr('.', '-')
    condition do
      issuable.respond_to?(:weight) &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
    end
    command :weight do |weight|
      if Issue.weight_filter_options.include?(weight.to_i)
        @updates[:weight] = weight.to_i
      end
    end

    desc 'Clear weight'
    condition do
      issuable.persisted? &&
        issuable.respond_to?(:weight) &&
        issuable.weight? &&
        current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
    end
    command :clear_weight do
      @updates[:weight] = nil
    end

    def find_label_ids(labels_param)
      label_ids_by_reference = extract_references(labels_param, :label).map(&:id)
      labels_ids_by_name = LabelsFinder.new(current_user, project_id: project.id, name: labels_param.split).execute.select(:id)

      label_ids_by_reference | labels_ids_by_name
    end

    def extract_references(arg, type)
      ext = Gitlab::ReferenceExtractor.new(project, current_user)
      ext.analyze(arg, author: current_user)

      ext.references(type)
    end
  end
end
