# frozen_string_literal: true

# rubocop:disable RSpec/AnyInstanceOf -- allow_next_instance_of relies on gitlab/rspec
module QA
  RSpec.describe Service::DockerRun::Smocker do
    let(:network) { "thenet" }
    let(:image) { "thiht/smocker:0.18.5" }
    let(:server_port) { 8080 }
    let(:config_port) { 8081 }
    let(:port_args) { "-e SMOCKER_MOCK_SERVER_LISTEN_PORT=#{server_port} -e SMOCKER_CONFIG_LISTEN_PORT=#{config_port}" }
    let(:base_cmd_pattern) { /docker run -d --network #{network} --name smocker-service-\w+ #{port_args}/ }

    subject(:container) { described_class.create }

    before do
      allow_any_instance_of(described_class).to receive(:shell).and_return("")
      allow_any_instance_of(described_class).to receive(:network).and_return(network)

      allow(Support::Waiter).to receive(:wait_until).and_return(true)
    end

    describe "#create" do
      context "with successful creation" do
        it "creates new instance of smocker container" do
          expect(container).to be_instance_of(described_class)
          expect(container).to have_received(:shell).with(/#{base_cmd_pattern} --publish-all #{image}/)
          expect(container.public_port).to eq(server_port)
          expect(container.admin_port).to eq(config_port)
        end
      end

      context "with failed creation" do
        before do
          allow(Support::Waiter).to receive(:wait_until).and_raise("error")
          allow(Runtime::Logger).to receive(:error)
          allow_any_instance_of(described_class).to receive(:shell)
            .with(/docker logs smocker-service-\w+/)
            .and_return("logs")
        end

        it "raises error" do
          expect { container }.to raise_error("error")
          expect(Runtime::Logger).to have_received(:error).with("Failed to start smocker container, logs:\nlogs")
        end
      end

      context "with host network" do
        let(:network) { "host" }
        let(:server_port) { 55020 }
        let(:config_port) { 55021 }

        let(:server) { instance_double(TCPServer, close: nil) }

        before do
          allow(TCPServer).to receive(:new).and_return(server)
          allow(server).to receive(:addr).and_return([nil, server_port], [nil, config_port])
        end

        it "set random open ports for smocker service" do
          expect(container).to have_received(:shell).with(/#{base_cmd_pattern} #{image}/)
          expect(container.public_port).to eq(server_port)
          expect(container.admin_port).to eq(config_port)
        end
      end
    end

    describe "#init" do
      let(:api) { instance_double(Vendor::Smocker::SmockerApi, wait_for_ready: true) }

      before do
        described_class.instance_variable_set(:@container, nil)

        allow(Vendor::Smocker::SmockerApi).to receive(:new).and_return(api)
        allow(described_class).to receive(:create).and_return(container)
        allow(container).to receive(:host_name).and_return('localhost')
        allow(container).to receive(:shell).with(/docker port smocker-service-\w+/).and_return(<<~PORTS)
          8080/tcp -> 0.0.0.0:55020
          8081/tcp -> 0.0.0.0:55021
        PORTS
      end

      it "create new instance of SmockerApi" do
        described_class.init(wait: 10) { |smocker_api| expect(smocker_api).to eq(api) }

        expect(Vendor::Smocker::SmockerApi).to have_received(:new).with(
          host: "localhost",
          public_port: 55020,
          admin_port: 55021
        )
        expect(api).to have_received(:wait_for_ready).with(wait: 10)
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstanceOf
