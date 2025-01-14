# frozen_string_literal: true

module Integrations
  module Base
    module Bamboo
      extend ActiveSupport::Concern

      class_methods do
        def title
          s_('BambooService|Atlassian Bamboo')
        end

        def description
          s_('BambooService|Run CI/CD pipelines with Atlassian Bamboo.')
        end

        def help
          build_help_page_url(
            'user/project/integrations/bamboo.md',
            s_('BambooService|Run CI/CD pipelines with Atlassian Bamboo. You must set up automatic revision ' \
              'labeling and a repository trigger in Bamboo.')
          )
        end

        def to_param
          'bamboo'
        end
      end

      included do
        include Base::Ci
        include ReactivelyCached
        prepend EnableSslVerification

        field :bamboo_url,
          title: -> { s_('BambooService|Bamboo URL') },
          placeholder: -> { s_('https://bamboo.example.com') },
          help: -> { s_('BambooService|Bamboo root URL.') },
          description: -> { s_('Bamboo root URL (for example, `https://bamboo.example.com`).') },
          exposes_secrets: true,
          required: true

        field :build_key,
          help: -> { s_('BambooService|Bamboo build plan key.') },
          description: -> { s_('Bamboo build plan key (for example, `KEY`).') },
          non_empty_password_title: -> { s_('BambooService|Enter new build key') },
          non_empty_password_help: -> { s_('BambooService|Leave blank to use your current build key.') },
          placeholder: -> { _('KEY') },
          required: true,
          is_secret: true

        field :username,
          help: -> { s_('BambooService|User with API access to the Bamboo server.') },
          description: -> { s_('User with API access to the Bamboo server.') },
          required: true

        field :password,
          type: :password,
          non_empty_password_title: -> { s_('ProjectService|Enter new password') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current password') },
          description: -> { s_('Password of the user.') },
          required: true

        with_options if: :activated? do
          validates :bamboo_url, presence: true, public_url: true
          validates :build_key, presence: true
        end

        validates :username, presence: true, if: ->(integration) { integration.activated? && integration.password }
        validates :password, presence: true, if: ->(integration) { integration.activated? && integration.username }

        attr_accessor :response

        def calculate_reactive_cache(sha, _ref)
          response = try_get_path("rest/api/latest/result/byChangeset/#{sha}")

          { build_page: read_build_page(response), commit_status: read_commit_status(response) }
        end

        def build_page(sha, ref)
          with_reactive_cache(sha, ref) { |cached| cached[:build_page] }
        end

        def commit_status(sha, ref)
          with_reactive_cache(sha, ref) { |cached| cached[:commit_status] }
        end
      end

      def execute(data)
        return unless supported_events.include?(data[:object_kind])

        get_path("updateAndBuild.action", { buildKey: build_key })
      end

      def avatar_url
        ActionController::Base.helpers.image_path(
          'illustrations/third-party-logos/integrations-logos/atlassian-bamboo.svg'
        )
      end

      private

      def get_build_result(response)
        return if response&.code != 200

        # May be nil if no result, a single result hash, or an array if multiple results for a given changeset.
        result = response.dig('results', 'results', 'result')

        # In case of multiple results, arbitrarily assume the last one is the most relevant.
        return result.last if result.is_a?(Array)

        result
      end

      def read_build_page(response)
        result = get_build_result(response)
        key =
          if result.blank?
            # If actual build link can't be determined, send user to build summary page.
            build_key
          else
            # If actual build link is available, go to build result page.
            result.dig('planResultKey', 'key')
          end

        build_url("browse/#{key}")
      end

      def read_commit_status(response)
        return :error unless response && (response.code == 200 || response.code == 404)

        result = get_build_result(response)
        status =
          if result.blank?
            'Pending'
          else
            result['buildState']
          end

        return :error unless status.present?

        if status.include?('Success')
          'success'
        elsif status.include?('Failed')
          'failed'
        elsif status.include?('Pending')
          'pending'
        else
          :error
        end
      end

      def try_get_path(path, query_params = {})
        params = build_get_params(query_params)
        params[:extra_log_info] = { project_id: project_id }

        Gitlab::HTTP.try_get(build_url(path), params)
      end

      def get_path(path, query_params = {})
        Gitlab::HTTP.get(build_url(path), build_get_params(query_params))
      end

      def build_url(path)
        Gitlab::Utils.append_path(bamboo_url, path)
      end

      def build_get_params(query_params)
        params = { verify: enable_ssl_verification, query: query_params }
        return params if username.blank? && password.blank?

        query_params[:os_authType] = 'basic'
        params[:basic_auth] = basic_auth
        params
      end

      def basic_auth
        { username: username, password: password }
      end
    end
  end
end
