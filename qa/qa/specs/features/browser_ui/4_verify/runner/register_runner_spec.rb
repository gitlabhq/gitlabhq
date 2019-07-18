# frozen_string_literal: true

module QA
  context 'Verify', :docker do
    describe 'Runner registration' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      after do
        Service::Runner.new(executor).remove!
      end

      it 'user registers a new specific runner' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        Resource::Runner.fabricate! do |runner|
          runner.name = executor
        end

        Page::Project::Settings::CICD.perform do |settings|
          sleep 5 # Runner should register within 5 seconds
          settings.refresh

          settings.expand_runners_settings do |page|
            expect(page).to have_content(executor)
            expect(page).to have_online_runner
          end
        end
      end
    end
  end
end
