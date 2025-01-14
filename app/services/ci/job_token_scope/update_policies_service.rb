# frozen_string_literal: true

module Ci
  module JobTokenScope
    class UpdatePoliciesService < ::BaseService
      include EditScopeValidations

      def execute(target, default_permissions, policies)
        return unless Feature.enabled?(:add_policies_to_ci_job_token, project)

        validate_target_exists!(target)
        validate_permissions!(target)

        link = find_link_using_source_and_target(target)

        return error_link_not_found unless link

        if link.update(default_permissions: default_permissions, job_token_policies: policies)
          ServiceResponse.success(payload: link)
        else
          error_updating(link)
        end

      rescue EditScopeValidations::ValidationError
        error_no_permissions
      rescue EditScopeValidations::NotFoundError
        error_target_not_found
      end

      private

      def error_target_not_found
        ServiceResponse.error(message: 'The target does not exist', reason: :not_found)
      end

      def error_no_permissions
        ServiceResponse.error(
          message: 'You have insufficient permission to update this job token scope',
          reason: :insufficient_permissions
        )
      end

      def error_link_not_found
        ServiceResponse.error(
          message: 'Unable to find a job token scope for the given project & target',
          reason: :not_found
        )
      end

      def error_updating(link)
        ServiceResponse.error(
          message: link&.errors&.full_messages&.to_sentence || 'Failed to update job token scope'
        )
      end

      def validate_permissions!(target)
        if target.is_a?(::Group)
          validate_source_project_and_target_group_access!(project, target, current_user)
        else
          validate_source_project_and_target_project_access!(project, target, current_user)
        end
      end

      def find_link_using_source_and_target(target)
        if target.is_a?(::Group)
          ::Ci::JobToken::GroupScopeLink.for_source_and_target(project, target)
        else
          ::Ci::JobToken::ProjectScopeLink.with_access_direction(:inbound).for_source_and_target(project, target)
        end
      end
    end
  end
end

Ci::JobTokenScope::UpdatePoliciesService.prepend_mod_with('Ci::JobTokenScope::UpdatePoliciesService')
