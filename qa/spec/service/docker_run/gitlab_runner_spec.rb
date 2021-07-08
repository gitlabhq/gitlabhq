# frozen_string_literal: true

module QA
  RSpec.describe Service::DockerRun::GitlabRunner do
    let(:runner_name) { 'test-runner' }
    let(:address) { 'gitlab.test' }
    let(:token) { 'abc123' }

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
      end

      context 'defaults' do
        before do
          register
        end

        it 'runs non-interactively' do
          expect(subject).to have_received(:shell).with(/ --non-interactive /)
        end

        it 'sets pertinent information' do
          expect(subject).to have_received(:shell).with(/--name #{runner_name} /)
          expect(subject).to have_received(:shell).with(/--url #{subject.address} /)
          expect(subject).to have_received(:shell).with(/--registration-token #{subject.token} /)
        end

        it 'runs untagged' do
          expect(subject).to have_received(:shell).with(/--run-untagged=true /)
        end

        it 'has no tags' do
          expect(subject.tags).to be_falsey
        end

        it 'runs daemonized' do
          expect(subject).to have_received(:shell).with(/ -d /)
        end

        it 'cleans itself up' do
          expect(subject).to have_received(:shell).with(/ --rm /)
        end
      end

      context 'running untagged' do
        before do
          register
        end

        it 'passes --run-untagged=true' do
          expect(subject).to have_received(:shell).with(/--run-untagged=true /)
        end

        it 'does not pass tag list' do
          expect(subject).not_to have_received(:shell).with(/--tag-list/)
        end
      end

      context 'running tagged' do
        context 'with only tags set' do
          before do
            subject.tags = tags

            register
          end

          it 'does not pass --run-untagged' do
            expect(subject).not_to have_received(:shell).with(/--run-untagged=true/)
          end

          it 'passes the tags with comma-separation' do
            expect(subject).to have_received(:shell).with(/--tag-list #{tags.join(',')} /)
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

      context 'executors' do
        it 'defaults to the shell executor' do
          register

          expect(subject).to have_received(:shell).with(/--executor shell /)
        end

        context 'docker' do
          before do
            subject.executor = :docker

            register
          end

          it 'specifies the docker executor' do
            expect(subject).to have_received(:shell).with(/--executor docker /)
          end

          it 'mounts the docker socket to the host runner' do
            expect(subject).to have_received(:shell).with(%r{-v /var/run/docker.sock:/var/run/docker.sock })
          end

          it 'runs in privileged mode' do
            expect(subject).to have_received(:shell).with(/--privileged /)
          end

          it 'has a default image' do
            expect(subject).to have_received(:shell).with(/--docker-image \b.+\b /)
          end

          it 'does not verify TLS' do
            expect(subject).to have_received(:shell).with(/--docker-tlsverify=false /)
          end

          it 'passes privileged mode' do
            expect(subject).to have_received(:shell).with(/--docker-privileged=true /)
          end

          it 'passes the host network' do
            expect(subject).to have_received(:shell).with(/--docker-network-mode=#{subject.network}/)
          end
        end
      end
    end

    describe '#tags=' do
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
end
