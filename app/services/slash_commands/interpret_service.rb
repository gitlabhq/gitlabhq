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

    desc ->(opts) { "Close this #{opts[:noteable].to_ability_name.humanize(capitalize: false)}" }
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].open? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"update_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :close do
      @updates[:state_event] = 'close'
    end

    desc ->(opts) { "Reopen this #{opts[:noteable].to_ability_name.humanize(capitalize: false)}" }
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].closed? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"update_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :open, :reopen do
      @updates[:state_event] = 'reopen'
    end

    desc 'Change title'
    params '<New title>'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].persisted? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"update_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :title do |title_param|
      @updates[:title] = title_param
    end

    desc 'Assign'
    params '@user'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :assign, :reassign do |assignee_param|
      user = extract_references(assignee_param, :user).first
      return unless user

      @updates[:assignee_id] = user.id
    end

    desc 'Remove assignee'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].assignee_id? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :unassign, :remove_assignee do
      @updates[:assignee_id] = nil
    end

    desc 'Set milestone'
    params '%"milestone"'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project]) &&
      opts[:project].milestones.active.any?
    end
    command :milestone do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      return unless milestone

      @updates[:milestone_id] = milestone.id
    end

    desc 'Remove milestone'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].milestone_id? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :clear_milestone, :remove_milestone do
      @updates[:milestone_id] = nil
    end

    desc 'Add label(s)'
    params '~label1 ~"label 2"'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project]) &&
      opts[:project].labels.any?
    end
    command :label, :labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:add_label_ids] = label_ids
    end

    desc 'Remove label(s)'
    params '~label1 ~"label 2"'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].labels.any? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :unlabel, :remove_label, :remove_labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:remove_label_ids] = label_ids
    end

    desc 'Remove all labels'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].labels.any? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"admin_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :clear_labels, :clear_label do
      @updates[:label_ids] = []
    end

    desc 'Add a todo'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].persisted? &&
      opts[:current_user] &&
      !TodosFinder.new(opts[:current_user]).execute.exists?(target: opts[:noteable])
    end
    command :todo do
      @updates[:todo_event] = 'add'
    end

    desc 'Mark todo as done'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      TodosFinder.new(opts[:current_user]).execute.exists?(target: opts[:noteable])
    end
    command :done do
      @updates[:todo_event] = 'done'
    end

    desc 'Subscribe'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      opts[:noteable].persisted? &&
      !opts[:noteable].subscribed?(opts[:current_user])
    end
    command :subscribe do
      @updates[:subscription_event] = 'subscribe'
    end

    desc 'Unsubscribe'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:current_user] &&
      opts[:noteable].persisted? &&
      opts[:noteable].subscribed?(opts[:current_user])
    end
    command :unsubscribe do
      @updates[:subscription_event] = 'unsubscribe'
    end

    desc 'Set due date'
    params 'a date in natural language'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].respond_to?(:due_date) &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"update_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :due_date, :due do |due_date_param|
      due_date = Chronic.parse(due_date_param).try(:to_date)

      @updates[:due_date] = due_date if due_date
    end

    desc 'Remove due date'
    condition ->(opts) do
      opts[:noteable] &&
      opts[:noteable].respond_to?(:due_date) &&
      opts[:noteable].due_date? &&
      opts[:current_user] &&
      opts[:project] &&
      opts[:current_user].can?(:"update_#{opts[:noteable].to_ability_name}", opts[:project])
    end
    command :clear_due_date do
      @updates[:due_date] = nil
    end

    # This is a dummy command, so that it appears in the autocomplete commands
    desc 'CC'
    params '@user'
    noop true
    command :cc do
      return
    end

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
