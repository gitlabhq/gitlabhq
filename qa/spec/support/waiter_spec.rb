# frozen_string_literal: true

require 'logger'

describe QA::Support::Waiter do
  before do
    logger = ::Logger.new $stdout
    logger.level = ::Logger::DEBUG
    QA::Runtime::Logger.logger = logger
  end

  describe '.wait' do
    context 'when the condition is true' do
      it 'logs the start' do
        expect { subject.wait(max: 0) {} }
        .to output(/with wait: max 0; interval 0.1/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.wait(max: 0) {} }
        .to output(/ended wait after .* seconds$/).to_stdout_from_any_process
      end
    end

    context 'when the condition is false' do
      it 'logs the start' do
        expect { subject.wait(max: 0) { false } }
        .to output(/with wait: max 0; interval 0.1/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.wait(max: 0) { false } }
        .to output(/ended wait after .* seconds$/).to_stdout_from_any_process
      end
    end
  end
end
