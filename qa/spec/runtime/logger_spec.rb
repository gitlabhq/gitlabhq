# frozen_string_literal: true

RSpec.describe QA::Runtime::Logger do
  before do
    logger = Logger.new $stdout
    logger.level = ::Logger::DEBUG
    described_class.logger = logger
  end

  it 'logs debug' do
    expect { described_class.debug('test') }.to output(/DEBUG -- : test/).to_stdout_from_any_process
  end

  it 'logs info' do
    expect { described_class.info('test') }.to output(/INFO -- : test/).to_stdout_from_any_process
  end

  it 'logs warn' do
    expect { described_class.warn('test') }.to output(/WARN -- : test/).to_stdout_from_any_process
  end

  it 'logs error' do
    expect { described_class.error('test') }.to output(/ERROR -- : test/).to_stdout_from_any_process
  end

  it 'logs fatal' do
    expect { described_class.fatal('test') }.to output(/FATAL -- : test/).to_stdout_from_any_process
  end

  it 'logs unknown' do
    expect { described_class.unknown('test') }.to output(/ANY -- : test/).to_stdout_from_any_process
  end
end
