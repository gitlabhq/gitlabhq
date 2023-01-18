# frozen_string_literal: true

module QA
  RSpec.describe 'Framework sanity', :orchestrated, :framework do
    describe 'Browser request interception' do
      before(:context) do
        skip 'Only can test for chrome' unless QA::Runtime::Env.can_intercept?
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
      end

      let(:page) { Capybara.current_session }
      let(:logger) { class_double('QA::Runtime::Logger') }

      it 'intercepts failed graphql calls' do
        page.execute_script <<~JS
        fetch('/api/graphql', {
          method: 'POST',
          body: JSON.stringify({ query: 'query {}'}),
          headers: { 'Content-Type': 'application/json' }
        })
        JS

        Support::Waiter.wait_until do
          !get_cached_error.nil?
        end
        expect(**get_cached_error).to include({ 'method' => 'POST', 'status' => 200, 'url' => '/api/graphql' })
      end

      def get_cached_error
        cache = page.execute_script <<~JS
        return Interceptor.getCache()
        JS

        cache['errors']&.first
      end
    end
  end
end
