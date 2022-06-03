# frozen_string_literal: true

RSpec.describe QA::Runtime::Logger do
  it 'returns logger instance' do
    expect(described_class.logger).to be_an_instance_of(ActiveSupport::Logger)
  end
end
