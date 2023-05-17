# rubocop:todo Naming/FileName
# frozen_string_literal: true

module QA
  module Resource
    class CICDSettings < QA::Resource::Base
      attributes :project_path,
        :inbound_job_token_scope_enabled

      attribute :mutation_id do
        SecureRandom.hex(6)
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        '/graphql'
      end

      alias_method :api_post_path, :api_get_path

      def api_post_body
        <<~GQL
          mutation  {
            projectCiCdSettingsUpdate(input: {
              clientMutationId: "#{mutation_id}"
              inboundJobTokenScopeEnabled: #{inbound_job_token_scope_enabled}
              fullPath: "#{project_path}"
            })
            {
              ciCdSettings {
                inboundJobTokenScopeEnabled
              }
              errors
            }
          }
        GQL
      end
    end
  end
end

# rubocop:enable Naming/FileName
