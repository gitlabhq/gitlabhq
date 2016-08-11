module SlashCommands
  class InterpretService < BaseService
    include Gitlab::SlashCommands::Dsl

    attr_reader :noteable

    # Takes a text and interpret the commands that are extracted from it.
    # Returns a hash of changes to be applied to a record.
    def execute(content, noteable)
      @noteable = noteable
      @updates = {}

      commands = extractor(noteable: noteable).extract_commands!(content)
      commands.each do |command|
        __send__(*command)
      end

      @updates
    end

    private

    def extractor(opts = {})
      opts.merge!(current_user: current_user, project: project)

      Gitlab::SlashCommands::Extractor.new(self.class.command_names(opts))
    end

    desc do
      "Close this #{noteable.to_ability_name.humanize(capitalize: false)}"
    end
    condition do
      noteable.open? &&
      current_user.can?(:"update_#{noteable.to_ability_name}", project)
    end
    command :close do
      @updates[:state_event] = 'close'
    end

    desc do
      "Reopen this #{noteable.to_ability_name.humanize(capitalize: false)}"
    end
    condition do
      noteable.closed? &&
      current_user.can?(:"update_#{noteable.to_ability_name}", project)
    end
    command :open, :reopen do
      @updates[:state_event] = 'reopen'
    end

    desc 'Change title'
    params '<New title>'
    condition do
      noteable.persisted? &&
      current_user.can?(:"update_#{noteable.to_ability_name}", project)
    end
    command :title do |title_param|
      @updates[:title] = title_param
    end

    desc 'Assign'
    params '@user'
    condition do
      current_user.can?(:"admin_#{noteable.to_ability_name}", project)
    end
    command :assign, :reassign do |assignee_param|
      user = extract_references(assignee_param, :user).first
      return unless user

      @updates[:assignee_id] = user.id
    end

    desc 'Remove assignee'
    condition do
      noteable.assignee_id? &&
      current_user.can?(:"admin_#{noteable.to_ability_name}", project)
    end
    command :unassign, :remove_assignee do
      @updates[:assignee_id] = nil
    end

    desc 'Set milestone'
    params '%"milestone"'
    condition do
      current_user.can?(:"admin_#{noteable.to_ability_name}", project) &&
      project.milestones.active.any?
    end
    command :milestone do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      return unless milestone

      @updates[:milestone_id] = milestone.id
    end

    desc 'Remove milestone'
    condition do
      noteable.milestone_id? &&
      current_user.can?(:"admin_#{noteable.to_ability_name}", project)
    end
    command :clear_milestone, :remove_milestone do
      @updates[:milestone_id] = nil
    end

    desc 'Add label(s)'
    params '~label1 ~"label 2"'
    condition do
      current_user.can?(:"admin_#{noteable.to_ability_name}", project) &&
      project.labels.any?
    end
    command :label, :labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:add_label_ids] = label_ids
    end

    desc 'Remove label(s)'
    params '~label1 ~"label 2"'
    condition do
      noteable.labels.any? &&
      current_user.can?(:"admin_#{noteable.to_ability_name}", project)
    end
    command :unlabel, :remove_label, :remove_labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:remove_label_ids] = label_ids
    end

    desc 'Remove all labels'
    condition do
      noteable.labels.any? &&
      current_user.can?(:"admin_#{noteable.to_ability_name}", project)
    end
    command :clear_labels, :clear_label do
      @updates[:label_ids] = []
    end

    desc 'Add a todo'
    condition do
      noteable.persisted? &&
      current_user &&
      !TodoService.new.todo_exist?(noteable, current_user)
    end
    command :todo do
      @updates[:todo_event] = 'add'
    end

    desc 'Mark todo as done'
    condition do
      current_user &&
      TodoService.new.todo_exist?(noteable, current_user)
    end
    command :done do
      @updates[:todo_event] = 'done'
    end

    desc 'Subscribe'
    condition do
      noteable.persisted? &&
      !noteable.subscribed?(current_user)
    end
    command :subscribe do
      @updates[:subscription_event] = 'subscribe'
    end

    desc 'Unsubscribe'
    condition do
      noteable.persisted? &&
      noteable.subscribed?(current_user)
    end
    command :unsubscribe do
      @updates[:subscription_event] = 'unsubscribe'
    end

    desc 'Set due date'
    params 'a date in natural language'
    condition do
      noteable.respond_to?(:due_date) &&
      current_user.can?(:"update_#{noteable.to_ability_name}", project)
    end
    command :due_date, :due do |due_date_param|
      due_date = Chronic.parse(due_date_param).try(:to_date)

      @updates[:due_date] = due_date if due_date
    end

    desc 'Remove due date'
    condition do
      noteable.respond_to?(:due_date) &&
      noteable.due_date? &&
      current_user.can?(:"update_#{noteable.to_ability_name}", project)
    end
    command :clear_due_date do
      @updates[:due_date] = nil
    end

    # This is a dummy command, so that it appears in the autocomplete commands
    desc 'CC'
    params '@user'
    command :cc, noop: true

    def find_label_ids(labels_param)
      extract_references(labels_param, :label).map(&:id)
    end

    def extract_references(cmd_arg, type)
      ext = Gitlab::ReferenceExtractor.new(project, current_user)
      ext.analyze(cmd_arg, author: current_user)

      ext.references(type)
    end
  end
end
