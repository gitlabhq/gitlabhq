# frozen_string_literal: true

module Gitlab
  module QuickActions
    module RelateActions
      extend ActiveSupport::Concern
      include ::Gitlab::QuickActions::Dsl

      included do
        desc { _('Link items related to this item') }
        explanation do |items|
          format(
            _('Added %{target} as a linked item related to this %{work_item_type}.'),
            target: dependency_service.format_refs(items),
            work_item_type: dependency_service.type_name
          )
        end
        execution_message do |items|
          format(
            _('Added %{target} as a linked item related to this %{work_item_type}.'),
            target: dependency_service.format_refs(items),
            work_item_type: dependency_service.type_name
          )
        end
        params { dependency_service.param_hint }
        types Issue
        condition { dependency_service.can_admin_link? }
        parse_params { |items| dependency_service.parse_params(items) }
        command :relate do |items|
          dependency_service.create_link(items, link_type: 'relates_to')
        end

        desc { _("Remove linked item") }
        explanation do |item|
          format(_('Removes linked item %{ref}.'), ref: dependency_service.format_ref(item))
        end
        execution_message do |item|
          format(_('Removed linked item %{ref}.'), ref: dependency_service.format_ref(item))
        end
        params { dependency_service.param_hint }
        types Issue, MergeRequest
        condition { dependency_service.can_admin_link? }
        parse_params do |item_param|
          dependency_service.parse_params(item_param).first
        end
        command :unlink do |item|
          next if dependency_service.destroy_link(item)

          @execution_message[:unlink] = _('No linked item matches the provided parameter.')
        end
      end

      private

      # Overridden in EE.
      def dependency_service
        @dependency_service ||= ::WorkItems::QuickActions::DependencyService.new(
          quick_action_target, current_user, project, group
        )
      end
    end
  end
end
