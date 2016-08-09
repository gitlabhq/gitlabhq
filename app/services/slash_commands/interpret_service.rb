module SlashCommands
  class InterpretService < BaseService
    include Gitlab::SlashCommands::Dsl

    attr_reader :noteable

    # Takes a text and interpret the commands that are extracted from it.
    # Returns a hash of changes to be applied to a record.
    def execute(content, noteable)
      @noteable = noteable
      @updates = {}

      commands = extractor.extract_commands!(content)
      commands.each do |command|
        __send__(*command)
      end

      @updates
    end

    private

    def extractor
      @extractor ||= Gitlab::SlashCommands::Extractor.new(self.class.command_names)
    end

    desc 'Close this issue or merge request'
    command :close do
      @updates[:state_event] = 'close'
    end

    desc 'Reopen this issue or merge request'
    command :open, :reopen do
      @updates[:state_event] = 'reopen'
    end

    desc 'Change title'
    params '<New title>'
    command :title do |title_param|
      @updates[:title] = title_param
    end

    desc 'Assign'
    params '@user'
    command :assign, :reassign do |assignee_param|
      user = extract_references(assignee_param, :user).first
      return unless user

      @updates[:assignee_id] = user.id
    end

    desc 'Remove assignee'
    command :unassign, :remove_assignee do
      @updates[:assignee_id] = nil
    end

    desc 'Set milestone'
    params '%"milestone"'
    command :milestone do |milestone_param|
      milestone = extract_references(milestone_param, :milestone).first
      return unless milestone

      @updates[:milestone_id] = milestone.id
    end

    desc 'Remove milestone'
    command :clear_milestone, :remove_milestone do
      @updates[:milestone_id] = nil
    end

    desc 'Add label(s)'
    params '~label1 ~"label 2"'
    command :label, :labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:add_label_ids] = label_ids
    end

    desc 'Remove label(s)'
    params '~label1 ~"label 2"'
    command :unlabel, :remove_label, :remove_labels do |labels_param|
      label_ids = find_label_ids(labels_param)
      return if label_ids.empty?

      @updates[:remove_label_ids] = label_ids
    end

    desc 'Remove all labels'
    command :clear_labels, :clear_label do
      @updates[:label_ids] = []
    end

    desc 'Add a todo'
    command :todo do
      @updates[:todo_event] = 'add'
    end

    desc 'Mark todo as done'
    command :done do
      @updates[:todo_event] = 'done'
    end

    desc 'Subscribe'
    command :subscribe do
      @updates[:subscription_event] = 'subscribe'
    end

    desc 'Unsubscribe'
    command :unsubscribe do
      @updates[:subscription_event] = 'unsubscribe'
    end

    desc 'Set a due date'
    params '<YYYY-MM-DD> | <N days>'
    command :due_date, :due do |due_date_param|
      return unless noteable.respond_to?(:due_date)

      due_date = begin
        if due_date_param.downcase == 'tomorrow'
          Date.tomorrow
        else
          Time.now + ChronicDuration.parse(due_date_param)
        end
      rescue ChronicDuration::DurationParseError
        Date.parse(due_date_param) rescue nil
      end

      @updates[:due_date] = due_date if due_date
    end

    desc 'Remove due date'
    command :clear_due_date do
      return unless noteable.respond_to?(:due_date)

      @updates[:due_date] = nil
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
