# frozen_string_literal: true

module QA
  RSpec.shared_context 'advanced search active' do
    let!(:advanced_search_on) { check_advanced_search_status }

    before do
      QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! unless advanced_search_on
    end

    # TODO: convert check_advanced_search_status method to use the API instead of the UI once the functionality exists
    # https://gitlab.com/gitlab-org/gitlab/-/issues/382849 and then we can resume turning off advanced search after the
    # tests as in the `after` block here. For now the advanced search tests will have the side effect of turning on
    # advanced search if it wasn't enabled before the tests run.

    # after do
    #   Runtime::Search.disable_elasticsearch(api_client) if !advanced_search_on && !api_client.nil?
    # end

    def check_advanced_search_status
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
