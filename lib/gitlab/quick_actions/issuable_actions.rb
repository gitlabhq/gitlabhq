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
          "Close this #{quick_action_target.to_ability_name.humanize(capitalize: false)}"
        end
        explanation do
          "Closes this #{quick_action_target.to_ability_name.humanize(capitalize: false)}."
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
          "Reopen this #{quick_action_target.to_ability_name.humanize(capitalize: false)}"
        end
        explanation do
          "Reopens this #{quick_action_target.to_ability_name.humanize(capitalize: false)}."
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
          _("Changes the title to \"%{title_param}\".") % { title_param: title_param }
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

          "Adds #{labels.join(' ')} #{'label'.pluralize(labels.count)}." if labels.any?
        end
        params '~label1 ~"label 2"'
        types Issuable
        condition do
          parent &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", parent) &&
            find_labels.any?
        end
        command :label do |labels_param|
          label_ids = find_label_ids(labels_param)

          if label_ids.any?
            @updates[:add_label_ids] ||= []
            @updates[:add_label_ids] += label_ids

            @updates[:add_label_ids].uniq!
          end
        end

        desc _('Remove all or specific label(s)')
        explanation do |labels_param = nil|
          if labels_param.present?
            labels = find_label_references(labels_param)
            "Removes #{labels.join(' ')} #{'label'.pluralize(labels.count)}." if labels.any?
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
          label_ids = find_label_ids(labels_param)

          if label_ids.any?
            @updates[:label_ids] ||= []
            @updates[:label_ids] += label_ids

            @updates[:label_ids].uniq!
          end
        end

        desc _('Add a todo')
        explanation _('Adds a todo.')
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
          "Subscribes to this #{quick_action_target.to_ability_name.humanize(capitalize: false)}."
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
          "Unsubscribes from this #{quick_action_target.to_ability_name.humanize(capitalize: false)}."
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
      end
    end
  end
end
