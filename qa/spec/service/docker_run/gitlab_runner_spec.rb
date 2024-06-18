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

        it 'sets token' do
          expect(subject).to have_received_masked_shell_command(/ --token \S+ /)
        end

        it 'runs daemonized' do
          expect(subject).to have_received_masked_shell_command(/ -d /)
        end

        it 'cleans itself up' do
          expect(subject).to have_received_masked_shell_command(/ --rm /)
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
