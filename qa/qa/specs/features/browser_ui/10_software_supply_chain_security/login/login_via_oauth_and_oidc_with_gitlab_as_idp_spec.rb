# frozen_string_literal: true

module QA
  # The consumer is a second GitLab that only cng-oauth-caproni deploys.
  RSpec.describe 'Software Supply Chain Security', :oauth, :skip_live_env, :skip_dedicated,
    requires_admin: 'creates users',
    only: { job: /cng-oauth-caproni/ },
    feature_category: :system_access do
    let!(:user) { Runtime::User::Store.test_user }
    let(:consumer_host) { Runtime::Env.oidc_consumer_url }

    shared_examples 'Instance OAuth Application' do |app_type|
      it "signs in to the consumer through the IdP with the #{app_type} provider" do
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        page.visit consumer_host

        expect(page.driver.current_url).to include(consumer_host)

        Page::Main::Login.perform do |login_page|
          login_page.public_send(:"sign_in_with_gitlab_#{app_type}")
        end

        expect { page.driver.current_url }
          .to eventually_include(Runtime::Scenario.gitlab_address).within(max_duration: 30)

        Flow::Login.sign_in(as: user, skip_page_validation: true)

        expect { page.driver.current_url }.to eventually_include(consumer_host).within(max_duration: 30)

        Page::Main::Menu.perform { |menu| expect(menu).to have_personal_area }
      end
    end

    describe 'OIDC' do
      it_behaves_like 'Instance OAuth Application', :oidc
    end

    describe 'OAuth' do
      it_behaves_like 'Instance OAuth Application', :oauth
    end
  end
end
