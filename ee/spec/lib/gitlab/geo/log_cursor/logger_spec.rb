require 'spec_helper'

describe Gitlab::Geo::LogCursor::Logger do
  class LoggerSpec; end

  subject(:logger) { described_class.new(LoggerSpec) }

  before do
    stub_const("#{described_class.name}::PID", 111)
  end

  it 'logs an info event' do
    expect(::Gitlab::Logger).to receive(:info).with(pid: 111,
                                                    class: "LoggerSpec",
                                                    message: 'Test')

    logger.info('Test')
  end

  it 'logs an error event' do
    expect(::Gitlab::Logger).to receive(:error).with(pid: 111,
                                                     class: "LoggerSpec",
                                                     message: 'Test')

    logger.error('Test')
  end

  describe '.event_info' do
    it 'logs an info event' do
      expect(::Gitlab::Logger).to receive(:info).with(pid: 111,
                                                      class: "LoggerSpec",
                                                      message: 'Test',
                                                      cursor_delay_s: 0.0)

      logger.event_info(Time.now, 'Test')
    end
  end
end
