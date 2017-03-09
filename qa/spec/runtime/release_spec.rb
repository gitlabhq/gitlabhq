describe QA::Runtime::Release do
  context 'when release version has extension strategy' do
    subject { described_class.new('CE') }
    let(:strategy) { spy('CE::Strategy') }

    before do
      stub_const('QA::CE::Strategy', strategy)
      stub_const('QA::EE::Strategy', strategy)
    end

    describe '#has_strategy?' do
      it 'return true' do
        expect(subject.has_strategy?).to be true
      end
    end

    describe '#strategy' do
      it 'return the strategy constant' do
        expect(subject.strategy).to eq QA::CE::Strategy
      end
    end

    describe 'delegated class methods' do
      it 'delegates all calls to strategy class' do
        described_class.some_method(1, 2)

        expect(strategy).to have_received(:some_method)
          .with(1, 2)
      end
    end
  end

  context 'when release version does not have extension strategy' do
    subject { described_class.new('CE') }

    before do
      hide_const('QA::CE::Strategy')
      hide_const('QA::EE::Strategy')
    end

    describe '#has_strategy?' do
      it 'returns false' do
        expect(subject.has_strategy?).to be false
      end
    end

    describe '#strategy' do
      it 'raises error' do
        expect { subject.strategy }.to raise_error(NameError)
      end
    end

    describe 'delegated class methods' do
      it 'behaves like a null object and does nothing' do
        expect { described_class.some_method(2, 3) }.not_to raise_error
      end
    end
  end

  context 'when release version is invalid or unspecified' do
    describe '#new' do
      it 'raises an exception' do
        expect { described_class.new(nil) }
          .to raise_error(described_class::UnspecifiedReleaseError)
      end
    end
  end
end
