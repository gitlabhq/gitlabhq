# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::Video do
    include QA::Support::Helpers::StubEnv

    let(:rspec_config) { instance_double('RSpec::Core::Configuration', prepend_before: nil, prepend_after: nil) }
    let(:video_recorder_image) { 'presidenten/selenoid-manual-video-recorder' }
    let(:video_recorder_version) { 'latest' }
    let(:selenoid_browser_image) { 'selenoid/chrome' }
    let(:selenoid_browser_version) { '111.0' }
    let(:remote_grid) { 'selenoid:4444' }
    let(:record_video) { 'true' }
    let(:use_selenoid) { 'true' }
    let(:allure_report) { 'false' }
    let(:docs_link) do
      'https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/running_against_remote_grid.md#testing-with-selenoid'
    end

    shared_examples 'video set up fails' do
      it 'does not perform configuration' do
        aggregate_failures do
          expect(QA::Runtime::Logger).to have_received(:warn)
            .with(/Test failure video recording setup failed!/)

          expect(RSpec).not_to have_received(:configure)
        end
      end
    end

    shared_examples 'video set up missing variable' do |missing_variable|
      let(:failure_message) do
        <<~FAIL.tr("\n", ' ').strip
          Aborting video recording setup!
          Missing variables: #{missing_variable} is required!
          See docs: #{docs_link}
        FAIL
      end

      it 'aborts video setup with warning' do
        aggregate_failures do
          expect(QA::Runtime::Logger).to have_received(:warn)
            .with(failure_message)

          expect(described_class).not_to have_received(:get_container_name)
          expect(RSpec).not_to have_received(:configure)
        end
      end
    end

    before do
      stub_env('QA_VIDEO_RECORDER_IMAGE', video_recorder_image)
      stub_env('QA_VIDEO_RECORDER_VERSION', video_recorder_version)
      stub_env('QA_SELENOID_BROWSER_IMAGE', selenoid_browser_image)
      stub_env('QA_SELENOID_BROWSER_VERSION', selenoid_browser_version)
      stub_env('QA_REMOTE_GRID', remote_grid)
      stub_env('USE_SELENOID', use_selenoid)
      stub_env('QA_RECORD_VIDEO', record_video)
      stub_env('QA_GENERATE_ALLURE_REPORT', allure_report)

      allow(RSpec).to receive(:configure).and_yield(rspec_config)
      allow(described_class).to receive(:get_container_name)
      allow(described_class).to receive(:shell)
      allow(QA::Runtime::Logger).to receive(:warn)
      allow(QA::Runtime::Logger).to receive(:info)
    end

    context 'with video disabled' do
      let(:record_video) { 'false' }

      before do
        described_class.configure!
      end

      it 'skips configuration' do
        aggregate_failures do
          expect(described_class).not_to have_received(:get_container_name)
          expect(described_class).not_to have_received(:shell)
          expect(RSpec).not_to have_received(:configure)
        end
      end
    end

    context 'with use_selenoid disabled' do
      let(:use_selenoid) { 'false' }

      before do
        described_class.configure!
      end

      it_behaves_like 'video set up missing variable', 'USE_SELENOID'
    end

    context 'without video_recorder_image set' do
      let(:video_recorder_image) { nil }

      before do
        described_class.configure!
      end

      it_behaves_like 'video set up missing variable', 'QA_VIDEO_RECORDER_IMAGE'
    end

    context 'without selenoid_browser_image set' do
      let(:selenoid_browser_image) { nil }

      before do
        described_class.configure!
      end

      it_behaves_like 'video set up missing variable', 'QA_SELENOID_BROWSER_IMAGE'
    end

    context 'without selenoid_browser_version set' do
      let(:selenoid_browser_version) { nil }

      before do
        described_class.configure!
      end

      it_behaves_like 'video set up missing variable', 'QA_SELENOID_BROWSER_VERSION'
    end

    context 'without browser_container_hostname' do
      before do
        allow(described_class).to receive(:get_container_name)
                                    .with(video_recorder_image)
                                    .and_return('recorder_container_name')
        allow(described_class).to receive(:get_container_name)
                                    .with("#{selenoid_browser_image}:#{selenoid_browser_version}")
                                    .and_return('browser_image_hostname')
        allow(described_class).to receive(:shell)
                                    .and_return(false)

        described_class.configure!
      end

      it_behaves_like 'video set up fails'
    end

    context 'without recorder_container_name' do
      before do
        allow(described_class).to receive(:get_container_name)
                                    .with(video_recorder_image)
                                    .and_return('')
        allow(described_class).to receive(:get_container_name)
                                    .with("#{selenoid_browser_image}:#{selenoid_browser_version}")
                                    .and_return('browser_image_hostname')
        allow(described_class).to receive(:shell)
                                    .and_return('browser_container_hostname')

        described_class.configure!
      end

      it_behaves_like 'video set up fails'
    end

    context 'with recorder_container_name and browser_container_hostname' do
      before do
        allow(described_class).to receive(:get_container_name)
                                    .with(video_recorder_image)
                                    .and_return('recorder_container_name')
        allow(described_class).to receive(:get_container_name)
                                    .with("#{selenoid_browser_image}:#{selenoid_browser_version}")
                                    .and_return('browser_image_hostname')
        allow(described_class).to receive(:shell)
                                    .and_return('browser_container_hostname')

        described_class.configure!
      end

      it 'performs configuration' do
        aggregate_failures do
          expect(QA::Runtime::Logger).to have_received(:info)
            .with(/Test failure video recording setup complete!/)
          expect(RSpec).to have_received(:configure)
          expect(rspec_config).to have_received(:prepend_before)
          expect(rspec_config).to have_received(:prepend_after)
        end
      end

      context 'with generate_allure_report' do
        let(:rspec_config) do
          instance_double('RSpec::Core::Configuration',
            prepend_before: nil,
            prepend_after: nil,
            append_after: nil)
        end

        let(:allure_report) { 'true' }

        it 'performs configuration with allure report' do
          aggregate_failures do
            expect(QA::Runtime::Logger).to have_received(:info)
              .with(/Test failure video recording setup complete!/)
            expect(RSpec).to have_received(:configure).twice
            expect(rspec_config).to have_received(:prepend_before)
            expect(rspec_config).to have_received(:prepend_after)
            expect(rspec_config).to have_received(:append_after)
          end
        end
      end
    end
  end
end
