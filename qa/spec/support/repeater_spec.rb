# frozen_string_literal: true

require 'logger'
require 'timecop'
require 'active_support/core_ext/integer/time'

describe QA::Support::Repeater do
  before do
    logger = ::Logger.new $stdout
    logger.level = ::Logger::DEBUG
    QA::Runtime::Logger.logger = logger
  end

  subject do
    Module.new do
      extend QA::Support::Repeater
    end
  end

  let(:time_start) { Time.now }
  let(:return_value) { "test passed" }

  describe '.repeat_until' do
    context 'when raise_on_failure is not provided (default: true)' do
      context 'when retry_on_exception is not provided (default: false)' do
        context 'when max_duration is provided' do
          context 'when max duration is reached' do
            it 'raises an exception' do
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_duration: 1) do
                    Timecop.travel(2)
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::WaitExceededError, "Wait condition not met after 1 second")
            end

            it 'ignores attempts' do
              loop_counter = 0

              expect(
                Timecop.freeze do
                  subject.repeat_until(max_duration: 1) do
                    loop_counter += 1

                    if loop_counter > 3
                      Timecop.travel(1)
                      return_value
                    else
                      false
                    end
                  end
                end
              ).to eq(return_value)
              expect(loop_counter).to eq(4)
            end
          end

          context 'when max duration is not reached' do
            it 'returns value from block' do
              Timecop.freeze(time_start) do
                expect(
                  subject.repeat_until(max_duration: 1) do
                    return_value
                  end
                ).to eq(return_value)
              end
            end
          end
        end

        context 'when max_attempts is provided' do
          context 'when max_attempts is reached' do
            it 'raises an exception' do
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 1) do
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::RetriesExceededError, "Retry condition not met after 1 attempt")
            end

            it 'ignores duration' do
              loop_counter = 0

              expect(
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 2) do
                    loop_counter += 1
                    Timecop.travel(1.year)

                    if loop_counter > 1
                      return_value
                    else
                      false
                    end
                  end
                end
              ).to eq(return_value)
              expect(loop_counter).to eq(2)
            end
          end

          context 'when max_attempts is not reached' do
            it 'returns value from block' do
              expect(
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 1) do
                    return_value
                  end
                end
              ).to eq(return_value)
            end
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          context 'when max_attempts is reached first' do
            it 'raises an exception' do
              loop_counter = 0
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 1, max_duration: 2) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::RetriesExceededError, "Retry condition not met after 1 attempt")
            end
          end

          context 'when max_duration is reached first' do
            it 'raises an exception' do
              loop_counter = 0
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 2, max_duration: 1) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::WaitExceededError, "Wait condition not met after 1 second")
            end
          end
        end
      end

      context 'when retry_on_exception is true' do
        context 'when max duration is reached' do
          it 'raises an exception' do
            Timecop.freeze do
              expect do
                subject.repeat_until(max_duration: 1, retry_on_exception: true) do
                  Timecop.travel(2)

                  raise "this should be raised"
                end
              end.to raise_error(RuntimeError, "this should be raised")
            end
          end

          it 'does not raise an exception until max_duration is reached' do
            loop_counter = 0

            Timecop.freeze(time_start) do
              expect do
                subject.repeat_until(max_duration: 2, retry_on_exception: true) do
                  loop_counter += 1
                  Timecop.travel(time_start + loop_counter)

                  raise "this should be raised"
                end
              end.to raise_error(RuntimeError, "this should be raised")
            end
            expect(loop_counter).to eq(2)
          end
        end

        context 'when max duration is not reached' do
          it 'returns value from block' do
            loop_counter = 0

            Timecop.freeze(time_start) do
              expect(
                subject.repeat_until(max_duration: 3, retry_on_exception: true) do
                  loop_counter += 1
                  Timecop.travel(time_start + loop_counter)

                  raise "this should not be raised" if loop_counter == 1

                  return_value
                end
              ).to eq(return_value)
            end
            expect(loop_counter).to eq(2)
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          context 'when max_attempts is reached first' do
            it 'raises an exception' do
              loop_counter = 0
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 1, max_duration: 2, retry_on_exception: true) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::RetriesExceededError, "Retry condition not met after 1 attempt")
            end
          end

          context 'when max_duration is reached first' do
            it 'raises an exception' do
              loop_counter = 0
              expect do
                Timecop.freeze do
                  subject.repeat_until(max_attempts: 2, max_duration: 1, retry_on_exception: true) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              end.to raise_error(QA::Support::Repeater::WaitExceededError, "Wait condition not met after 1 second")
            end
          end
        end
      end
    end

    context 'when raise_on_failure is false' do
      context 'when retry_on_exception is not provided (default: false)' do
        context 'when max duration is reached' do
          def test_wait
            Timecop.freeze do
              subject.repeat_until(max_duration: 1, raise_on_failure: false) do
                Timecop.travel(2)
                return_value
              end
            end
          end

          it 'does not raise an exception' do
            expect { test_wait }.not_to raise_error
          end

          it 'returns the value from the block' do
            expect(test_wait).to eq(return_value)
          end
        end

        context 'when max duration is not reached' do
          it 'returns the value from the block' do
            Timecop.freeze do
              expect(
                subject.repeat_until(max_duration: 1, raise_on_failure: false) do
                  return_value
                end
              ).to eq(return_value)
            end
          end

          it 'raises an exception' do
            Timecop.freeze do
              expect do
                subject.repeat_until(max_duration: 1, raise_on_failure: false) do
                  raise "this should be raised"
                end
              end.to raise_error(RuntimeError, "this should be raised")
            end
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          shared_examples 'repeat until' do |max_attempts:, max_duration:|
            it "returns when #{max_attempts < max_duration ? 'max_attempts' : 'max_duration'} is reached" do
              loop_counter = 0

              expect(
                Timecop.freeze do
                  subject.repeat_until(max_attempts: max_attempts, max_duration: max_duration, raise_on_failure: false) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              ).to eq(false)
              expect(loop_counter).to eq(1)
            end
          end

          context 'when max_attempts is reached first' do
            it_behaves_like 'repeat until', max_attempts: 1, max_duration: 2
          end

          context 'when max_duration is reached first' do
            it_behaves_like 'repeat until', max_attempts: 2, max_duration: 1
          end
        end
      end

      context 'when retry_on_exception is true' do
        context 'when max duration is reached' do
          def test_wait
            Timecop.freeze do
              subject.repeat_until(max_duration: 1, raise_on_failure: false, retry_on_exception: true) do
                Timecop.travel(2)
                return_value
              end
            end
          end

          it 'does not raise an exception' do
            expect { test_wait }.not_to raise_error
          end

          it 'returns the value from the block' do
            expect(test_wait).to eq(return_value)
          end
        end

        context 'when max duration is not reached' do
          before do
            @loop_counter = 0
          end

          def test_wait_with_counter
            Timecop.freeze(time_start) do
              subject.repeat_until(max_duration: 3, raise_on_failure: false, retry_on_exception: true) do
                @loop_counter += 1
                Timecop.travel(time_start + @loop_counter)

                raise "this should not be raised" if @loop_counter == 1

                return_value
              end
            end
          end

          it 'does not raise an exception' do
            expect { test_wait_with_counter }.not_to raise_error
          end

          it 'returns the value from the block' do
            expect(test_wait_with_counter).to eq(return_value)
            expect(@loop_counter).to eq(2)
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          shared_examples 'repeat until' do |max_attempts:, max_duration:|
            it "returns when #{max_attempts < max_duration ? 'max_attempts' : 'max_duration'} is reached" do
              loop_counter = 0

              expect(
                Timecop.freeze do
                  subject.repeat_until(max_attempts: max_attempts, max_duration: max_duration, raise_on_failure: false, retry_on_exception: true) do
                    loop_counter += 1
                    Timecop.travel(time_start + loop_counter)
                    false
                  end
                end
              ).to eq(false)
              expect(loop_counter).to eq(1)
            end
          end

          context 'when max_attempts is reached first' do
            it_behaves_like 'repeat until', max_attempts: 1, max_duration: 2
          end

          context 'when max_duration is reached first' do
            it_behaves_like 'repeat until', max_attempts: 2, max_duration: 1
          end
        end
      end
    end
  end
end
