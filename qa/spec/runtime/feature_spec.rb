# frozen_string_literal: true

RSpec.describe QA::Runtime::Feature do
  let(:api_client) { double('QA::Runtime::API::Client') }
  let(:request) { Struct.new(:url).new('http://api') }
  let(:response_post) { Struct.new(:code).new(201) }

  before do
    allow(described_class).to receive(:api_client).and_return(api_client)
  end

  where(:feature_flag) do
    ['a_flag', :a_flag]
  end

  with_them do
    shared_examples 'enables a feature flag' do
      it 'enables a feature flag for a scope' do
        allow(described_class).to receive(:get)
          .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a_flag", "state": "on" }]'))

        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features/a_flag").and_return(request)
        expect(described_class).to receive(:post)
          .with(request.url, { value: true, scope => actor_name }).and_return(response_post)
        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features").and_return(request)
        expect(QA::Runtime::Logger).to receive(:info).with("Enabling feature: a_flag for scope \"#{scope}: #{actor_name}\"")
        expect(QA::Runtime::Logger).to receive(:info).with("Successfully enabled and verified feature flag: a_flag")

        described_class.enable(feature_flag, scope => actor)
      end
    end

    shared_examples 'disables a feature flag' do
      it 'disables a feature flag for a scope' do
        allow(described_class).to receive(:get)
          .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a_flag", "state": "off" }]'))

        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features/a_flag").and_return(request)
        expect(described_class).to receive(:post)
          .with(request.url, { value: false, scope => actor_name }).and_return(response_post)
        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features").and_return(request)
        expect(QA::Runtime::Logger).to receive(:info).with("Disabling feature: a_flag for scope \"#{scope}: #{actor_name}\"")
        expect(QA::Runtime::Logger).to receive(:info).with("Successfully disabled and verified feature flag: a_flag")

        described_class.disable(feature_flag, scope => actor )
      end
    end

    shared_examples 'checks a feature flag' do
      context 'when the flag is enabled for a scope' do
        it 'returns the feature flag state' do
          expect(QA::Runtime::API::Request)
            .to receive(:new)
            .with(api_client, "/features")
            .and_return(request)
          expect(described_class)
            .to receive(:get)
            .and_return(Struct.new(:code, :body).new(200, %Q([{ "name": "a_flag", "state": "conditional", "gates": #{gates} }])))

          expect(described_class.enabled?(feature_flag, scope => actor)).to be_truthy
        end
      end
    end

    describe '.enable' do
      it 'enables a feature flag' do
        allow(described_class).to receive(:get)
          .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a_flag", "state": "on" }]'))

        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features/a_flag").and_return(request)
        expect(described_class).to receive(:post)
          .with(request.url, { value: true }).and_return(response_post)
        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features").and_return(request)

        described_class.enable(feature_flag)
      end

      context 'when a project scope is provided' do
        it_behaves_like 'enables a feature flag' do
          let(:scope) { :project }
          let(:actor_name) { 'group-name/project-name' }
          let(:actor) { Struct.new(:full_path).new(actor_name) }
        end
      end

      context 'when a group scope is provided' do
        it_behaves_like 'enables a feature flag' do
          let(:scope) { :group }
          let(:actor_name) { 'group-name' }
          let(:actor) { Struct.new(:full_path).new(actor_name) }
        end
      end

      context 'when a user scope is provided' do
        it_behaves_like 'enables a feature flag' do
          let(:scope) { :user }
          let(:actor_name) { 'user-name' }
          let(:actor) { Struct.new(:username).new(actor_name) }
        end
      end

      context 'when a feature group scope is provided' do
        it_behaves_like 'enables a feature flag' do
          let(:scope) { :feature_group }
          let(:actor_name) { 'foo' }
          let(:actor) { "foo" }
        end
      end
    end

    describe '.disable' do
      it 'disables a feature flag' do
        allow(described_class).to receive(:get)
          .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a_flag", "state": "off" }]'))

        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features/a_flag").and_return(request)
        expect(described_class).to receive(:post)
          .with(request.url, { value: false }).and_return(response_post)
        expect(QA::Runtime::API::Request).to receive(:new)
          .with(api_client, "/features").and_return(request)

        described_class.disable(feature_flag)
      end

      context 'when a project scope is provided' do
        it_behaves_like 'disables a feature flag' do
          let(:scope) { :project }
          let(:actor_name) { 'group-name/project-name' }
          let(:actor) { Struct.new(:full_path).new(actor_name) }
        end
      end

      context 'when a group scope is provided' do
        it_behaves_like 'disables a feature flag' do
          let(:scope) { :group }
          let(:actor_name) { 'group-name' }
          let(:actor) { Struct.new(:full_path).new(actor_name) }
        end
      end

      context 'when a user scope is provided' do
        it_behaves_like 'disables a feature flag' do
          let(:scope) { :user }
          let(:actor_name) { 'user-name' }
          let(:actor) { Struct.new(:username).new(actor_name) }
        end
      end

      context 'when a feature group scope is provided' do
        it_behaves_like 'disables a feature flag' do
          let(:scope) { :feature_group }
          let(:actor_name) { 'foo' }
          let(:actor) { "foo" }
        end
      end
    end

    describe '.enabled?' do
      it 'returns a feature flag state' do
        expect(QA::Runtime::API::Request)
          .to receive(:new)
          .with(api_client, "/features")
          .and_return(request)
        expect(described_class)
          .to receive(:get)
          .and_return(Struct.new(:code, :body).new(200, '[{ "name": "a_flag", "state": "on" }]'))

        expect(described_class.enabled?(feature_flag)).to be_truthy
      end

      context 'when a project scope is provided' do
        it_behaves_like 'checks a feature flag' do
          let(:scope) { :project }
          let(:actor_name) { 'group-name/project-name' }
          let(:actor) { Struct.new(:full_path, :id).new(actor_name, 270) }
          let(:gates) { %q([{"key": "actors", "value": ["Project:270"]}]) }
        end
      end

      context 'when a group scope is provided' do
        it_behaves_like 'checks a feature flag' do
          let(:scope) { :group }
          let(:actor_name) { 'group-name' }
          let(:actor) { Struct.new(:full_path, :id).new(actor_name, 33) }
          let(:gates) { %q([{"key": "actors", "value": ["Group:33"]}]) }
        end
      end

      context 'when a user scope is provided' do
        it_behaves_like 'checks a feature flag' do
          let(:scope) { :user }
          let(:actor_name) { 'user-name' }
          let(:actor) { Struct.new(:full_path, :id).new(actor_name, 13) }
          let(:gates) { %q([{"key": "actors", "value": ["User:13"]}]) }
        end
      end

      context 'when a feature group scope is provided' do
        it_behaves_like 'checks a feature flag' do
          let(:scope) { :feature_group }
          let(:actor_name) { 'foo' }
          let(:actor) { "foo" }
          let(:gates) { %q([{"key": "groups", "value": ["foo"]}]) }
        end
      end
    end
  end
end
