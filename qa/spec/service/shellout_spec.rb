# frozen_string_literal: true

module QA
  RSpec.describe Service::Shellout do
    let(:wait_thread) { instance_double('Thread') }
    let(:errored_wait) { instance_double('Process::Status', exited?: true, exitstatus: 1) }
    let(:non_errored_wait) { instance_double('Process::Status', exited?: true, exitstatus: 0) }
    let(:stdin) { StringIO.new }
    let(:stdout) { [+'logged in as user with password secret'] }

    context 'when masking secrets' do
      before do
        allow(Open3).to receive(:popen2e).and_yield(stdin, stdout, wait_thread)
      end

      it 'masks secrets when logging the command itself' do
        expect(Runtime::Logger).to receive(:info).with('Executing: `docker login -u **** -p ****`')
        expect(wait_thread).to receive(:value).twice.and_return(non_errored_wait)
        subject.shell('docker login -u user -p secret', mask_secrets: %w[secret user])
      end

      it 'masks command secrets on CommandError' do
        expect(wait_thread).to receive(:value).twice.and_return(errored_wait)

        expect { subject.shell('docker login -u user -p secret', mask_secrets: %w[secret user]) }
          .to raise_error(Service::Shellout::CommandError) do |error|
            expect(error.to_s).to include('Command: `docker login -u **** -p ****` failed')
          end
      end

      it 'masking secrets is optional' do
        expect(wait_thread).to receive(:value).twice.and_return(errored_wait)

        expect { subject.shell('docker pull ruby:3') }.to raise_error(Service::Shellout::CommandError) do |error|
          expect(error.to_s).to include('Command: `docker pull ruby:3` failed')
        end
      end

      it 'masks secrets when yielding output' do
        expect(wait_thread).to receive(:value).twice.and_return(non_errored_wait)

        subject.shell('docker login -u user -p secret', mask_secrets: %w[secret user]) do |output|
          expect(output).not_to be(nil)
          expect(output).to eql('logged in as **** with password ****')
        end
      end

      it 'masks secrets in debug logs' do
        expect(Runtime::Logger).to receive(:debug).with(/logged in as \*\*\*\* with password \*\*\*\*/)
        expect(wait_thread).to receive(:value).twice.and_return(non_errored_wait)

        subject.shell('docker login -u user -p secret', mask_secrets: %w[secret user])
      end

      it 'masks secrets in error logs' do
        expect(Runtime::Logger).to receive(:error).with(/logged in as \*\*\*\* with password \*\*\*\*/)
        expect(wait_thread).to receive(:value).twice.and_return(errored_wait)

        expect { subject.shell('docker login -u user -p secret', mask_secrets: %w[secret user]) }
          .to raise_error(Service::Shellout::CommandError)
      end
    end
  end
end
