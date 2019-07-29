# frozen_string_literal: true

module Gitlab
  module QuickActions
    module IssuableActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      SHRUG = '¯\\＿(ツ)＿/¯'.freeze
      TABLEFLIP = '(╯°□°)╯︵ ┻━┻'.freeze

      included do
        # Issue, MergeRequest, Epic: quick actions definitions
        desc do
          _('Close this %{quick_action_target}') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        explanation do
          _('Closes this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        execution_message do
          _('Closed this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        types Issuable
        condition do
          quick_action_target.persisted? &&
            quick_action_target.open? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :close do
          @updates[:state_event] = 'close'
        end

        desc do
          _('Reopen this %{quick_action_target}') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        explanation do
          _('Reopens this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        execution_message do
          _('Reopened this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        types Issuable
        condition do
          quick_action_target.persisted? &&
            quick_action_target.closed? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :reopen do
          @updates[:state_event] = 'reopen'
        end

        desc _('Change title')
        explanation do |title_param|
          _('Changes the title to "%{title_param}".') % { title_param: title_param }
        end
        execution_message do |title_param|
          _('Changed the title to "%{title_param}".') % { title_param: title_param }
        end
        params '<New title>'
        types Issuable
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :title do |title_param|
          @updates[:title] = title_param
        end

        desc _('Add label(s)')
        explanation do |labels_param|
          labels = find_label_references(labels_param)

          if labels.any?
            _("Adds %{labels} %{label_text}.") %
              { labels: labels.join(' '), label_text: 'label'.pluralize(labels.count) }
          end
        end
        params '~label1 ~"label 2"'
        types Issuable
        condition do
          parent &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", parent) &&
            find_labels.any?
        end
        command :label do |labels_param|
          run_label_command(labels: find_labels(labels_param), command: :label, updates_key: :add_label_ids)
        end

        desc _('Remove all or specific label(s)')
        explanation do |labels_param = nil|
          label_references = labels_param.present? ? find_label_references(labels_param) : []
          if label_references.any?
            _("Removes %{label_references} %{label_text}.") %
              { label_references: label_references.join(' '), label_text: 'label'.pluralize(label_references.count) }
          else
            _('Removes all labels.')
          end
        end
        params '~label1 ~"label 2"'
        types Issuable
        condition do
          quick_action_target.persisted? &&
            quick_action_target.labels.any? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", parent)
        end
        command :unlabel do |labels_param = nil|
          if labels_param.present?
            labels = find_labels(labels_param)
            label_ids = labels.map(&:id)
            label_references = labels_to_reference(labels, :name)

            if label_ids.any?
              @updates[:remove_label_ids] ||= []
              @updates[:remove_label_ids] += label_ids

              @updates[:remove_label_ids].uniq!
            end
          else
            @updates[:label_ids] = []
            label_references = []
          end

          @execution_message[:unlabel] = remove_label_message(label_references)
        end

        desc _('Replace all label(s)')
        explanation do |labels_param|
          labels = find_label_references(labels_param)
          "Replaces all labels with #{labels.join(' ')} #{'label'.pluralize(labels.count)}." if labels.any?
        end
        params '~label1 ~"label 2"'
        types Issuable
        condition do
          quick_action_target.persisted? &&
            quick_action_target.labels.any? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", parent)
        end
        command :relabel do |labels_param|
          run_label_command(labels: find_labels(labels_param), command: :relabel, updates_key: :label_ids)
        end

        desc _('Add a todo')
        explanation _('Adds a todo.')
        execution_message _('Added a todo.')
        types Issuable
        condition do
          quick_action_target.persisted? &&
            !TodoService.new.todo_exist?(quick_action_target, current_user)
        end
        command :todo do
          @updates[:todo_event] = 'add'
        end

        desc _('Mark to do as done')
        explanation _('Marks to do as done.')
        execution_message _('Marked to do as done.')
        types Issuable
        condition do
          quick_action_target.persisted? &&
            TodoService.new.todo_exist?(quick_action_target, current_user)
        end
        command :done do
          @updates[:todo_event] = 'done'
        end

        desc _('Subscribe')
        explanation do
          _('Subscribes to this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        execution_message do
          _('Subscribed to this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        types Issuable
        condition do
          quick_action_target.persisted? &&
            !quick_action_target.subscribed?(current_user, project)
        end
        command :subscribe do
          @updates[:subscription_event] = 'subscribe'
        end

        desc _('Unsubscribe')
        explanation do
          _('Unsubscribes from this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        execution_message do
          _('Unsubscribed from this %{quick_action_target}.') %
            { quick_action_target: quick_action_target.to_ability_name.humanize(capitalize: false) }
        end
        types Issuable
        condition do
          quick_action_target.persisted? &&
            quick_action_target.subscribed?(current_user, project)
        end
        command :unsubscribe do
          @updates[:subscription_event] = 'unsubscribe'
        end

        desc _('Toggle emoji award')
        explanation do |name|
          _("Toggles :%{name}: emoji award.") % { name: name } if name
        end
        execution_message do |name|
          _("Toggled :%{name}: emoji award.") % { name: name } if name
        end
        params ':emoji:'
        types Issuable
        condition do
          quick_action_target.persisted?
        end
        parse_params do |emoji_param|
          match = emoji_param.match(Banzai::Filter::EmojiFilter.emoji_pattern)
          match[1] if match
        end
        command :award do |name|
          if name && quick_action_target.user_can_award?(current_user)
            @updates[:emoji_award] = name
          end
        end

        desc _("Append the comment with %{shrug}") % { shrug: SHRUG }
        params '<Comment>'
        types Issuable
        substitution :shrug do |comment|
          "#{comment} #{SHRUG}"
        end

        desc _("Append the comment with %{TABLEFLIP}") % { tableflip: TABLEFLIP }
        params '<Comment>'
        types Issuable
        substitution :tableflip do |comment|
          "#{comment} #{TABLEFLIP}"
        end

        private

        def run_label_command(labels:, command:, updates_key:)
          return if labels.empty?

          @updates[updates_key] ||= []
          @updates[updates_key] += labels.map(&:id)
          @updates[updates_key].uniq!

          label_references = labels_to_reference(labels, :name)
          @execution_message[command] = case command
                                        when :relabel
                                          _('Replaced all labels with %{label_references} %{label_text}.') %
                                            {
                                            label_references: label_references.join(' '),
                                            label_text: 'label'.pluralize(label_references.count)
                                          }
                                        when :label
                                          _('Added %{label_references} %{label_text}.') %
                                            {
                                            label_references: label_references.join(' '),
                                            label_text: 'label'.pluralize(labels.count)
                                          }
                                        end
        end

        def remove_label_message(label_references)
          if label_references.any?
            _("Removed %{label_references} %{label_text}.") %
              { label_references: label_references.join(' '), label_text: 'label'.pluralize(label_references.count) }
          else
            _('Removed all labels.')
          end
        end
      end
    end
  end
end
