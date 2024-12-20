# frozen_string_literal: true

module QA
  # This context checks if advanced search is enabled and functioning,
  # and enables it via the API if the test isn't running on Staging.
  #
  # In orchestrated tests (test environments using self-managed instances
  # that aren't shared) , we can enable elasticsearch if it's not already enabled.
  #
  # However, on Staging we shouldn't try to enable elasticsearch if it appears
  # to be disabled. We could end up changing the settings inappropriately.
  # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19015
  RSpec.shared_context 'advanced search active', :requires_admin do
    let(:admin_api_client) { Runtime::User::Store.admin_api_client }
    let!(:advanced_search_on) { check_advanced_search_status }

    before do
      QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! unless advanced_search_on
    end

    def check_advanced_search_status
      return false unless Runtime::Search.elasticsearch_on?(admin_api_client)
      return true if advanced_search_enabled_in_ui?

      return false unless QA::Specs::Helpers::ContextSelector.context_matches?({ subdomain: %i[staging
        staging-canary] })

      raise Runtime::Search::ElasticSearchServerError,
        "Advanced search does not appear to be enabled. Please confirm that Elasticsearch is configured correctly"
    end

    def advanced_search_enabled_in_ui?
      Flow::Login.sign_in
      QA::Support::Retrier.retry_on_exception(
        max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
        sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL) do
        QA::Page::Main::Menu.perform do |menu|
          menu.search_for('lorem ipsum')
        end
        page.has_text?('Advanced search is enabled')
      end
    end
  end
end
