# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CollaborativeEditing::BaseChannel, feature_category: :wiki do
  let_it_be(:user) { create(:user) }

  let(:channel) { described_class.new(connection, {}) }
  let(:document) { instance_double(WikiPage) }

  before do
    stub_action_cable_connection current_user: user
  end

  describe 'the subclass contract' do
    let(:container) { instance_double(Project) }

    it 'requires a subclass to supply the container' do
      expect { channel.send(:find_container) }.to raise_error(NotImplementedError)
    end

    it 'requires a subclass to supply the document' do
      expect { channel.send(:find_document, container) }.to raise_error(NotImplementedError)
    end

    it 'requires a subclass to supply the authorization check' do
      expect { channel.send(:authorized?, container) }.to raise_error(NotImplementedError)
    end

    it 'requires a subclass to supply the document key' do
      expect { channel.send(:document_key, container, document) }.to raise_error(NotImplementedError)
    end

    it 'requires a subclass to supply the feature check' do
      expect { channel.send(:feature_enabled?, container) }.to raise_error(NotImplementedError)
    end
  end

  describe '#receive' do
    it 'ignores a message from a client that never established a stream' do
      expect(ActionCable.server).not_to receive(:broadcast)

      channel.receive({ 'type' => 'sync', 'payload' => 'an-update' })
    end
  end
end
