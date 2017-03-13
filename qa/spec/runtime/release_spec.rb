describe QA::Runtime::Release do
  context 'when release version has extension strategy' do
    subject { described_class.new('VER') }
    let(:strategy) { spy('VER::Strategy') }

    before do
      stub_const('QA::VER::Strategy', strategy)
    end

    describe '#has_strategy?' do
      it 'return true' do
        expect(subject.has_strategy?).to be true
      end
    end

    describe '#strategy' do
      it 'return the strategy constant' do
        expect(subject.strategy).to eq QA::VER::Strategy
      end
    end

    describe 'delegated class methods' do
      before do
        allow_any_instance_of(described_class)
          .to receive(:has_strategy?).and_return(true)

        allow_any_instance_of(described_class)
          .to receive(:strategy).and_return(strategy)
      end

      it 'delegates all calls to strategy class' do
        described_class.some_method(1, 2)

        expect(strategy).to have_received(:some_method)
          .with(1, 2)
      end
    end
  end

  context 'when release version does not have extension strategy' do
    subject { described_class.new('NOVER') }

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

    describe 'does not delegate class methods' do
      before do
        allow_any_instance_of(described_class)
          .to receive(:has_strategy?).and_return(false)
      end

      it 'behaves like a null object and does nothing' do
        expect { described_class.some_method(2, 3) }.not_to raise_error
      end

      it 'returns nil' do
        expect(described_class.something).to be_nil
      end

      it 'does not delegate to strategy object' do
        expect_any_instance_of(described_class)
          .not_to receive(:strategy)
      end
    end
  end
end
