# frozen_string_literal: true

module QA
  RSpec.shared_context 'with streamed events mock setup' do
    let!(:mock_service) { QA::Support::AuditEventStreamingService.new }
    let!(:stream_destination_url) { mock_service.destination_url }

    let(:stream_destination) do
      EE::Resource::InstanceAuditEventExternalDestination.fabricate_via_api! do |resource|
        resource.destination_url = stream_destination_url
      end
    end

    after do |example|
      stream_destination.remove_via_api!

      # If there is a failure this will output the logs from the smocker container (at the debug log level)
      mock_service.container_logs if example.exception
      mock_service.teardown!
    end
  end
end
