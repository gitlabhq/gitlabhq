# frozen_string_literal: true

shared_examples_for 'a Geo event store' do |event_class|
  context 'when running on a secondary node' do
    before do
      stub_secondary_node
    end

    it 'does not create an event ' do
      expect { subject.create! }.not_to change(event_class, :count)
    end
  end

  context 'when running on a primary node' do
    before do
      stub_primary_node
    end

    it 'does not create an event if there are no secondary nodes' do
      allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

      expect { subject.create! }.not_to change(event_class, :count)
    end

    it 'creates an event' do
      expect { subject.create! }.to change(event_class, :count).by(1)
    end

    context 'when file subject is not on local store' do
      before do
        skip 'No file subject defined, skipping' unless defined?(file_subject)

        allow(file_subject).to receive(:local?).and_return(false)
      end

      it 'creates an event' do
        expect { subject.create! }.to change(event_class, :count).by(1)
      end
    end
  end
end
