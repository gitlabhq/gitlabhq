# frozen_string_literal: true

RSpec.describe QA::Resource::Events::Base do
  let(:resource) do
    Class.new(QA::Resource::Base) do
      def api_get_path
        '/foo'
      end
    end
  end

  subject { resource.tap { |f| f.include(described_class) }.new }

  describe "#events" do
    it 'fetches all events when called without parameters' do
      allow(subject).to receive(:parse_body).and_return('returned')

      expect(subject).to receive(:api_get_from).with('/foo/events')
      expect(subject.events).to eq('returned')
    end

    it 'fetches events with a specified action type' do
      allow(subject).to receive(:parse_body).and_return('returned')

      expect(subject).to receive(:api_get_from).with('/foo/events?action=pushed')
      expect(subject.events(action: 'pushed')).to eq('returned')
    end
  end
end
