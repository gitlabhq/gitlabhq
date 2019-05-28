# frozen_string_literal: true

module QuickActions
  class InterpretService < BaseService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::QuickActions::Dsl
    include Gitlab::QuickActions::IssueActions
    include Gitlab::QuickActions::IssueAndMergeRequestActions
    include Gitlab::QuickActions::IssuableActions
    include Gitlab::QuickActions::MergeRequestActions
    include Gitlab::QuickActions::CommitActions
    include Gitlab::QuickActions::CommonActions

    attr_reader :quick_action_target

    # Counts how many commands have been executed.
    # Used to display relevant feedback on UI when a note
    # with only commands has been processed.
    attr_accessor :commands_executed_count

    # Takes an quick_action_target and returns an array of all the available commands
    # represented with .to_h
    def available_commands(quick_action_target)
      @quick_action_target = quick_action_target

      self.class.command_definitions.map do |definition|
        next unless definition.available?(self)

        definition.to_h(self)
      end.compact
    end

    # Takes a text and interprets the commands that are extracted from it.
    # Returns the content without commands, and hash of changes to be applied to a record.
    def execute(content, quick_action_target, only: nil)
      return [content, {}] unless current_user.can?(:use_quick_actions)

      @quick_action_target = quick_action_target
      @updates = {}

      content, commands = extractor.extract_commands(content, only: only)
      extract_updates(commands)

      [content, @updates]
    end

    # Takes a text and interprets the commands that are extracted from it.
    # Returns the content without commands, and array of changes explained.
    def explain(content, quick_action_target)
      return [content, []] unless current_user.can?(:use_quick_actions)

      @quick_action_target = quick_action_target

      content, commands = extractor.extract_commands(content)
      commands = explain_commands(commands)
      [content, commands]
    end

    private

    def extractor
      Gitlab::QuickActions::Extractor.new(self.class.command_definitions)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def extract_users(params)
      return [] if params.nil?

      users = extract_references(params, :user)

      if users.empty?
        users =
          if params.strip == 'me'
            [current_user]
          else
            User.where(username: params.split(' ').map(&:strip))
          end
      end

      users
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_milestones(project, params = {})
      MilestonesFinder.new(params.merge(project_ids: [project.id], group_ids: [project.group&.id])).execute
    end

    def parent
      project || group
    end

    def group
      strong_memoize(:group) do
        quick_action_target.group if quick_action_target.respond_to?(:group)
      end
    end

    def find_labels(labels_params = nil)
      extract_references(labels_params, :label) | find_labels_by_name_no_tilde(labels_params)
    end

    def find_labels_by_name_no_tilde(labels_params)
      return Label.none if label_with_tilde?(labels_params)

      finder_params = { include_ancestor_groups: true }
      finder_params[:project_id] = project.id if project
      finder_params[:group_id] = group.id if group
      finder_params[:name] = extract_label_names(labels_params) if labels_params

      LabelsFinder.new(current_user, finder_params).execute
    end

    def label_with_tilde?(labels_params)
      labels_params&.include?('~')
    end

    def extract_label_names(labels_params)
      # '"A" "A B C" A B' => ["A", "A B C", "A", "B"]
      labels_params.scan(/"([^"]+)"|([^ ]+)/).flatten.compact
    end

    def find_label_references(labels_param)
      find_labels(labels_param).map(&:to_reference)
    end

    def find_label_ids(labels_param)
      find_labels(labels_param).map(&:id)
    end

    def explain_commands(commands)
      commands.map do |name, arg|
        definition = self.class.definition_by_name(name)
        next unless definition

        definition.explain(self, arg)
      end.compact
    end

    def extract_updates(commands)
      commands.each do |name, arg|
        definition = self.class.definition_by_name(name)
        next unless definition

        definition.execute(self, arg)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def extract_references(arg, type)
      return [] unless arg

      ext = Gitlab::ReferenceExtractor.new(project, current_user)

      ext.analyze(arg, author: current_user, group: group)

      ext.references(type)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
