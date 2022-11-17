# frozen_string_literal: true

require 'active_support/core_ext/integer/time'
require 'active_support/testing/time_helpers'

RSpec.describe QA::Support::Repeater do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    Module.new do
      extend QA::Support::Repeater
    end
  end

  let(:return_value) { "test passed" }

  after do
    travel_back
  end

  describe '.repeat_until' do
    context 'when raise_on_failure is not provided (default: true)' do
      context 'when retry_on_exception is not provided (default: false)' do
        context 'when max_duration is provided' do
          context 'when max duration is reached' do
            it 'raises an exception with default message' do
              expect do
                subject.repeat_until(max_duration: 1) { travel(2.seconds) && false }
              end.to raise_error(QA::Support::Repeater::WaitExceededError, "Wait failed after 1 second")
            end

            it 'raises an exception with custom message' do
              message = 'Some custom action'

              expect do
                subject.repeat_until(max_duration: 1, message: message) { travel(2.seconds) && false }
              end.to raise_error(QA::Support::Repeater::WaitExceededError, "#{message} failed after 1 second")
            end

            it 'ignores attempts' do
              loop_counter = 0

              expect(
                subject.repeat_until(max_duration: 1) do
                  loop_counter += 1

                  if loop_counter > 3
                    travel(1.second)
                    return_value
                  else
                    false
                  end
                end
              ).to eq(return_value)
              expect(loop_counter).to eq(4)
            end
          end

          context 'when max duration is not reached' do
            it 'returns value from block' do
              expect(subject.repeat_until(max_duration: 10) { return_value }).to eq(return_value)
            end
          end
        end

        context 'when max_attempts is provided' do
          context 'when max_attempts is reached' do
            it 'raises an exception with default message' do
              expect { subject.repeat_until(max_attempts: 1) { false } }.to raise_error(
                QA::Support::Repeater::RetriesExceededError, "Retry failed after 1 attempt"
              )
            end

            it 'raises an exception with custom message' do
              message = 'Some custom action'

              expect { subject.repeat_until(max_attempts: 1, message: message) { false } }.to raise_error(
                QA::Support::Repeater::RetriesExceededError, "#{message} failed after 1 attempt"
              )
            end

            it 'ignores duration' do
              loop_counter = 0

              expect(
                subject.repeat_until(max_attempts: 2) do
                  loop_counter += 1
                  travel(1.year)

                  if loop_counter > 1
                    return_value
                  else
                    false
                  end
                end
              ).to eq(return_value)
              expect(loop_counter).to eq(2)
            end
          end

          context 'when max_attempts is not reached' do
            it 'returns value from block' do
              expect(subject.repeat_until(max_attempts: 1) { return_value }).to eq(return_value)
            end
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          context 'when max_attempts is reached first' do
            it 'raises an exception' do
              expect { subject.repeat_until(max_attempts: 1, max_duration: 2) { false } }.to(
                raise_error(QA::Support::Repeater::RetriesExceededError, "Retry failed after 1 attempt")
              )
            end
          end

          context 'when max_duration is reached first' do
            it 'raises an exception' do
              expect { subject.repeat_until(max_attempts: 2, max_duration: 1) { travel(10.seconds) && false } }.to(
                raise_error(QA::Support::Repeater::WaitExceededError, "Wait failed after 1 second")
              )
            end
          end
        end
      end

      context 'when retry_on_exception is true' do
        context 'when max duration is reached' do
          it 'raises an exception' do
            expect do
              subject.repeat_until(max_duration: 1, retry_on_exception: true) do
                travel(10.seconds)

                raise "this should be raised"
              end
            end.to raise_error(RuntimeError, "this should be raised")
          end

          it 'does not raise an exception until max_duration is reached' do
            loop_counter = 0

            expect do
              subject.repeat_until(max_duration: 5, retry_on_exception: true) do
                loop_counter += 1
                travel(10.seconds) if loop_counter == 2

                raise "this should be raised"
              end
            end.to raise_error(RuntimeError, "this should be raised")
            expect(loop_counter).to eq(2)
          end
        end

        context 'when max duration is not reached' do
          it 'returns value from block' do
            loop_counter = 0

            expect(
              subject.repeat_until(max_duration: 3, retry_on_exception: true) do
                loop_counter += 1

                raise "this should not be raised" if loop_counter == 1

                return_value
              end
            ).to eq(return_value)
            expect(loop_counter).to eq(2)
          end
        end
      end
    end

    context 'when raise_on_failure is false' do
      context 'when retry_on_exception is not provided (default: false)' do
        context 'when max duration is reached' do
          def test_wait
            subject.repeat_until(max_duration: 1, raise_on_failure: false) do
              travel(10.seconds)
              return_value
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
            expect(subject.repeat_until(max_duration: 10, raise_on_failure: false) { return_value }).to eq(return_value)
          end

          it 'raises an exception' do
            expect do
              subject.repeat_until(max_duration: 10, raise_on_failure: false) do
                raise "this should be raised"
              end
            end.to raise_error(RuntimeError, "this should be raised")
          end
        end

        context 'when both max_attempts and max_duration are provided' do
          shared_examples 'repeat until' do |max_attempts:, max_duration:|
            it "returns when #{max_attempts < max_duration ? 'max_attempts' : 'max_duration'} is reached" do
              loop_counter = 0

              expect(
                subject.repeat_until(max_attempts: max_attempts, max_duration: max_duration, raise_on_failure: false) do
                  loop_counter += 1
                  travel(max_attempts.seconds)
                  false
                end
              ).to eq(false)
              expect(loop_counter).to eq(1)
            end
          end

          context 'when max_attempts is reached first' do
            it_behaves_like 'repeat until', max_attempts: 1, max_duration: 10
          end

          context 'when max_duration is reached first' do
            it_behaves_like 'repeat until', max_attempts: 2, max_duration: 1
          end
        end
      end

      context 'when retry_on_exception is true' do
        context 'when max duration is reached' do
          def test_wait
            subject.repeat_until(max_duration: 1, raise_on_failure: false, retry_on_exception: true) do
              travel(10.seconds)
              return_value
            end
          end

          it 'does not raise an exception' do
            expect { test_wait }.not_to raise_error
          end

          it 'returns the value from the block' do
            expect(test_wait).to eq(return_value)
          end
        end
      end
    end

    context 'with logging' do
      before do
        allow(QA::Runtime::Logger).to receive(:debug)
      end

      it 'skips logging single attempt with max_attempts' do
        subject.repeat_until(max_attempts: 3) do
          true
        end

        expect(QA::Runtime::Logger).not_to have_received(:debug)
      end

      it 'skips logging single attempt with max_duration' do
        subject.repeat_until(max_duration: 3) do
          true
        end

        expect(QA::Runtime::Logger).not_to have_received(:debug)
      end

      it 'allows logging to be silenced' do
        subject.repeat_until(max_attempts: 3, log: false, raise_on_failure: false) do
          false
        end

        expect(QA::Runtime::Logger).not_to have_received(:debug)
      end

      it 'starts logging on subsequent attempts for max_duration' do
        subject.repeat_until(max_duration: 0.3, sleep_interval: 0.1, raise_on_failure: false) do
          false
        end

        aggregate_failures do
          expect(QA::Runtime::Logger).to have_received(:debug).with(<<~MSG.strip).ordered.once
            Retrying action with: max_duration: 0.3; sleep_interval: 0.1; raise_on_failure: false; retry_on_exception: false
          MSG
          expect(QA::Runtime::Logger).to have_received(:debug).with('ended retry').ordered.once
          expect(QA::Runtime::Logger).not_to have_received(:debug).with(/Attempt number/)
        end
      end

      it 'starts logging subsequent attempts for max_attempts' do
        attempts = 0
        subject.repeat_until(max_attempts: 4, raise_on_failure: false) do
          next true if attempts == 2

          attempts += 1
          false
        end

        aggregate_failures do
          expect(QA::Runtime::Logger).to have_received(:debug).with(<<~MSG.strip).ordered.once
            Retrying action with: max_attempts: 4; sleep_interval: 0; raise_on_failure: false; retry_on_exception: false
          MSG
          expect(QA::Runtime::Logger).to have_received(:debug).with('Attempt number 2').ordered.once
          expect(QA::Runtime::Logger).to have_received(:debug).with('Attempt number 3').ordered.once
          expect(QA::Runtime::Logger).to have_received(:debug).with('ended retry').ordered.once
        end
      end
    end
  end
end
