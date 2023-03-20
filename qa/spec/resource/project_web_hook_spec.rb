# frozen_string_literal: true

module QA
  RSpec.describe Resource::ProjectWebHook do
    let(:smocker_api) { instance_double(Vendor::Smocker::SmockerApi) }
    let(:smocker_docker) { class_double(Service::DockerRun::Smocker) }
    let(:history_entries) do
      [
        {
          request: {
            body: {
              object_kind: 'tag_push'
            }
          }
        },
        {
          request: {
            body: {
              object_kind: 'merge_request'
            }
          }
        }
      ]
    end

    let(:history_response) { Struct.new(:body).new(history_entries.to_json) }

    it 'configures the project hook events' do
      setup_mocks

      described_class.setup(pipeline: true, wiki_page: true) do |webhook, _|
        expect(webhook.pipeline_events).to be(true)
        expect(webhook.wiki_page_events).to be(true)
        expect(webhook.push_events).to be(false)
      end
    end

    it 'adds an #event method to the smocker object that returns webhook events' do
      setup_mocks

      # rubocop:disable RSpec/AnyInstanceOf
      expect_any_instance_of(Vendor::Smocker::SmockerApi).to receive(:get_session_id)
                                                               .and_return('123')
      expect_any_instance_of(Vendor::Smocker::SmockerApi).to receive(:get)
                                                               .with(/history/)
                                                               .and_return(history_response)
      # rubocop:enable RSpec/AnyInstanceOf

      described_class.setup do |_, smocker|
        expect(smocker.events('123')).to include(
          a_hash_including(object_kind: 'merge_request'),
          a_hash_including(object_kind: 'tag_push')
        )
      end
    end

    def setup_mocks
      # rubocop:disable RSpec/AnyInstanceOf
      expect_any_instance_of(Vendor::Smocker::SmockerApi).to receive(:reset)
      expect_any_instance_of(Vendor::Smocker::SmockerApi).to receive(:register)
      # rubocop:enable RSpec/AnyInstanceOf

      expect(Service::DockerRun::Smocker).to receive(:init)
                                               .and_yield(Vendor::Smocker::SmockerApi.new(host: 'smocker.net'))
      allow(subject).to receive(:project)
      allow(described_class).to receive(:fabricate_via_api!)
                                  .and_yield(subject)
    end
  end
end
