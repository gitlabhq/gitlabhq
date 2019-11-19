# frozen_string_literal: true

module QA
  context 'Verify', :docker do
    describe 'Runner registration' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      after do
        Service::DockerRun::GitlabRunner.new(executor).remove!
      end

      it 'user registers a new specific runner' do
        Flow::Login.sign_in

        Resource::Runner.fabricate! do |runner|
          runner.name = executor
        end.project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CICD.perform do |settings|
          sleep 5 # Runner should register within 5 seconds

          settings.expand_runners_settings do |page|
            expect(page).to have_content(executor)
            expect(page).to have_online_runner
          end
        end
      end
    end
  end
end
