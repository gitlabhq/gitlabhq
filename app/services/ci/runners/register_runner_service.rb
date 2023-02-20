# frozen_string_literal: true

module Ci
  module Runners
    class RegisterRunnerService
      def execute(registration_token, attributes)
        runner_type_attrs = extract_runner_type_attrs(registration_token)

        return ServiceResponse.error(message: 'invalid token supplied', http_status: :forbidden) unless runner_type_attrs

        runner = ::Ci::Runner.new(attributes.merge(runner_type_attrs))

        Ci::BulkInsertableTags.with_bulk_insert_tags do
          Ci::Runner.transaction do
            if runner.save
              Gitlab::Ci::Tags::BulkInsert.bulk_insert_tags!([runner])
            else
              raise ActiveRecord::Rollback
            end
          end
        end

        ServiceResponse.success(payload: { runner: runner })
      end

      private

      def extract_runner_type_attrs(registration_token)
        @attrs_from_token ||= check_token(registration_token)

        return unless @attrs_from_token

        attrs = @attrs_from_token.clone
        case attrs[:runner_type]
        when :project_type
          attrs[:projects] = [attrs.delete(:scope)]
        when :group_type
          attrs[:groups] = [attrs.delete(:scope)]
        end

        attrs
      end

      def check_token(registration_token)
        if runner_registration_token_valid?(registration_token)
          # Create shared runner. Requires admin access
          { runner_type: :instance_type }
        elsif runner_registrar_valid?('project') && project = ::Project.find_by_runners_token(registration_token)
          # Create a project runner
          { runner_type: :project_type, scope: project }
        elsif runner_registrar_valid?('group') && group = ::Group.find_by_runners_token(registration_token)
          # Create a group runner
          { runner_type: :group_type, scope: group }
        end
      end

      def runner_registration_token_valid?(registration_token)
        ActiveSupport::SecurityUtils.secure_compare(registration_token, Gitlab::CurrentSettings.runners_registration_token)
      end

      def runner_registrar_valid?(type)
        Gitlab::CurrentSettings.valid_runner_registrars.include?(type)
      end

      def token_scope
        @attrs_from_token[:scope]
      end
    end
  end
end

Ci::Runners::RegisterRunnerService.prepend_mod
