# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::GitlabRunner do
    let(:runner_name) { 'test-runner' }
    let(:address) { 'gitlab.test' }
    let(:token) { 'glrt-abc123' }

    let(:tags) { %w[qa test] }

    subject do
      described_class.new(runner_name).tap do |runner|
        runner.address = address
        runner.token = token
      end
    end

    it 'defaults to run untagged' do
      expect(subject.run_untagged).to be(true)
    end

    describe '#register!' do
      let(:register) { subject.send(:register!) }

      before do
        allow(subject).to receive(:shell)
        allow(subject).to receive(:wait_until_running_and_configured)
      end

      context 'defaults' do
        before do
          register
        end

        it 'runs non-interactively' do
          expect(subject).to have_received_masked_shell_command(/ --non-interactive /)
        end

        it 'sets pertinent information' do
          expect(subject).to have_received_masked_shell_command(/ --name #{runner_name} /)
          expect(subject).to have_received_masked_shell_command(/ --url #{subject.address} /)
        end

        it 'masks the token' do
          expect(subject).to have_received(:shell).with(/#{subject.token}/, mask_secrets: [subject.token])
        end

        context 'with registration token' do
          let(:token) { 'abc123' }

          it 'sets registration-token' do
            expect(subject).to have_received_masked_shell_command(/ --registration-token \S+ /)
          end

          it 'does not set token' do
            expect(subject).not_to have_received_masked_shell_command(/ --token \S+ /)
          end

          it 'runs untagged' do
            expect(subject).to have_received_masked_shell_command(/ --run-untagged=true /)
          end

          it 'does not pass tag list' do
            expect(subject).not_to have_received_masked_shell_command(/ --tag-list /)
          end
        end

        context 'with authentication token' do
          let(:token) { 'glrt-abc123' }

          it 'sets token' do
            expect(subject).to have_received_masked_shell_command(/ --token \S+ /)
          end

          it 'does not set registration-token' do
            expect(subject).not_to have_received_masked_shell_command(/ --registration-token \S+ /)
          end

          it 'does not set tags' do
            expect(subject).not_to have_received_masked_shell_command(/ --tag-list /)
          end

          it 'does not pass --run-untagged' do
            expect(subject).not_to have_received_masked_shell_command(/ --run-untagged=true /)
          end
        end

        it 'has no tags' do
          expect(subject.tags).to be_falsey
        end

        it 'runs daemonized' do
          expect(subject).to have_received_masked_shell_command(/ -d /)
        end

        it 'cleans itself up' do
          expect(subject).to have_received_masked_shell_command(/ --rm /)
        end
      end

      context 'with registration token' do
        let(:token) { 'abc123' }

        context 'running tagged' do
          context 'with only tags set' do
            before do
              subject.tags = tags

              register
            end

            it 'does not pass --run-untagged' do
              expect(subject).not_to have_received_masked_shell_command(/ --run-untagged=true /)
            end

            it 'passes the tags with comma-separation' do
              expect(subject).to have_received_masked_shell_command(/ --tag-list #{tags.join(',')} /)
            end
          end

          context 'with specifying only run_untagged' do
            before do
              subject.run_untagged = false
            end

            it 'raises an error if tags are not specified' do
              expect { register }.to raise_error(/must specify tags/i)
            end
          end

          context 'when specifying contradicting variables' do
            before do
              subject.tags = tags
              subject.run_untagged = true
            end

            it 'raises an error' do
              expect { register }.to raise_error(/conflicting options/i)
            end
          end
        end

        context 'when tags are specified' do
          before do
            subject.tags = tags
          end

          it 'sets the tags' do
            expect(subject.tags).to eq(tags)
          end

          it 'sets run_untagged' do
            expect(subject.run_untagged).to be(false)
          end
        end
      end

      context 'executors' do
        it 'defaults to the shell executor' do
          register

          expect(subject).to have_received_masked_shell_command(/ --executor shell /)
        end

        context 'docker' do
          before do
            subject.executor = :docker

            register
          end

          it 'specifies the docker executor' do
            expect(subject).to have_received_masked_shell_command(/ --executor docker /)
          end

          it 'mounts the docker socket to the host runner' do
            expect(subject).to have_received_masked_shell_command(%r{-v /var/run/docker.sock:/var/run/docker.sock })
          end

          it 'runs in privileged mode' do
            expect(subject).to have_received_masked_shell_command(/ --privileged /)
          end

          it 'has a default image' do
            expect(subject).to have_received_masked_shell_command(/ --docker-image \b.+\b /)
          end

          it 'does not verify TLS' do
            expect(subject).to have_received_masked_shell_command(/ --docker-tlsverify=false /)
          end

          it 'passes privileged mode' do
            expect(subject).to have_received_masked_shell_command(/ --docker-privileged=true /)
          end

          it 'passes the host network' do
            expect(subject).to have_received_masked_shell_command(/ --docker-network-mode=#{subject.network} /)
          end
        end
      end
    end

    describe '#unregister!' do
      let(:run_unregister_command) { subject.send(:run_unregister_command!) }

      before do
        allow(subject).to receive(:shell)

        subject.instance_eval do
          def runner_auth_token
            token
          end
        end

        run_unregister_command
      end

      it 'sets url' do
        expect(subject).to have_received_masked_shell_command(/ --url #{subject.address} /)
      end

      it 'sets masked token' do
        auth_token = subject.runner_auth_token
        expect(subject).to have_received_masked_shell_command(/ --token #{auth_token}/)
      end
    end

    RSpec::Matchers.define "have_received_masked_shell_command" do |cmd|
      match do |actual|
        expect(actual).to have_received(:shell).with(cmd, mask_secrets: anything)
      end

      match_when_negated do |actual|
        expect(actual).not_to have_received(:shell).with(cmd, mask_secrets: anything)
      end
    end
  end
end
