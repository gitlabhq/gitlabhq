# frozen_string_literal: true

describe QA::Specs::Runner do
  context '#perform' do
    before do
      allow(QA::Runtime::Browser).to receive(:configure!)
    end

    it 'excludes the orchestrated tag by default' do
      expect(RSpec::Core::Runner).to receive(:run)
        .with(['--tag', '~orchestrated', File.expand_path('../../qa/specs/features', __dir__)], $stderr, $stdout)
        .and_return(0)

      subject.perform
    end

    context 'when tty is set' do
      subject do
        described_class.new.tap do |runner|
          runner.tty = true
        end
      end

      it 'sets the `--tty` flag' do
        expect(RSpec::Core::Runner).to receive(:run)
          .with(['--tty', '--tag', '~orchestrated', File.expand_path('../../qa/specs/features', __dir__)], $stderr, $stdout)
          .and_return(0)

        subject.perform
      end
    end

    context 'when tags are set' do
      subject do
        described_class.new.tap do |runner|
          runner.tags = %i[orchestrated github]
        end
      end

      it 'focuses on the given tags' do
        expect(RSpec::Core::Runner).to receive(:run)
          .with(['--tag', 'orchestrated', '--tag', 'github', File.expand_path('../../qa/specs/features', __dir__)], $stderr, $stdout)
          .and_return(0)

        subject.perform
      end
    end
  end
end
