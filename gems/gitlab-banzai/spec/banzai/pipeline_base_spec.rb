# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::PipelineBase do
  it 'subclasses HTML::Pipeline' do
    expect(described_class <= ::HTML::Pipeline).to be_truthy
  end

  describe '.filter_subscription_name' do
    it 'adds the thread id to the subscription name' do
      expect(described_class.filter_subscription_name)
        .to eq("call_filter.html_pipeline_#{Thread.current.object_id}")
    end

    it 'differs between threads' do
      other = Thread.new { described_class.filter_subscription_name }.value

      expect(other).not_to eq(described_class.filter_subscription_name)
    end
  end

  describe '#perform_filter' do
    around do |example|
      # `Banzai::Renderer` does this in the monolith.
      described_class.default_instrumentation_service = ActiveSupport::Notifications
      example.run
    ensure
      described_class.default_instrumentation_service = nil
    end

    it 'instruments each filter under the thread-local subscription name' do
      events = []
      subscription = ActiveSupport::Notifications
        .subscribe(described_class.filter_subscription_name) do |_name, _start, _finish, _id, payload|
          events << payload[:filter]
        end

      described_class.new([Banzai::Filter::TrimWhitespaceFilter]).call(' text ')

      expect(events).to eq(['Banzai::Filter::TrimWhitespaceFilter'])
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end
  end
end
