# frozen_string_literal: true

module QA
  RSpec.describe Vendor::Smocker::SmockerApi do
    let(:host) { 'smocker.bar' }

    subject { described_class.new(host: host) }

    it 'retries until the service is ready' do
      expect(subject).to receive(:get)
                           .and_raise(StandardError)
                           .and_raise(StandardError)
                           .and_return(200)

      expect { subject.wait_for_ready }.not_to raise_error
    end
  end
end
