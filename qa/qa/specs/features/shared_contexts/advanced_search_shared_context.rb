# frozen_string_literal: true

module QA
  RSpec.shared_context 'advanced search active' do
    let!(:advanced_search_on) { check_advanced_search_status }

    before do
      QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! unless advanced_search_on
    end

    after do
      Runtime::Search.disable_elasticsearch(api_client) if !advanced_search_on && !api_client.nil?
    end

    # TODO: convert this method to use the API instead of the UI once the functionality exists
    # https://gitlab.com/gitlab-org/gitlab/-/issues/382849
    def check_advanced_search_status
      Flow::Login.sign_in
      QA::Page::Main::Menu.perform do |menu|
        menu.search_for('lorem ipsum')
      end
      page.has_text?('Advanced search is enabled')
    end
  end
end
