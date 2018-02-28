describe QA::Factory::Dependency do
  let(:dependency) { spy('dependency' ) }
  let(:factory) { spy('factory') }
  let(:block) { spy('block') }

  let(:signature) do
    double('signature', factory: dependency, block: block)
  end

  subject do
    described_class.new(:mydep, factory, signature)
  end

  describe '#overridden?' do
    it 'returns true if factory has overridden dependency' do
      allow(factory).to receive(:mydep).and_return('something')

      expect(subject).to be_overridden
    end

    it 'returns false if dependency has not been overridden' do
      allow(factory).to receive(:mydep).and_return(nil)

      expect(subject).not_to be_overridden
    end
  end

  describe '#build!' do
    context 'when dependency has been overridden' do
      before do
        allow(subject).to receive(:overridden?).and_return(true)
      end

      it 'does not fabricate dependency' do
        subject.build!

        expect(dependency).not_to have_received(:fabricate!)
      end
    end

    context 'when dependency has not been overridden' do
      before do
        allow(subject).to receive(:overridden?).and_return(false)
      end

      it 'fabricates dependency' do
        subject.build!

        expect(dependency).to have_received(:fabricate!)
      end

      it 'sets product in the factory' do
        subject.build!

        expect(factory).to have_received(:mydep=).with(dependency)
      end

      context 'when receives a caller factory as block argument' do
        let(:dependency) { QA::Factory::Base }

        it 'calls given block with dependency factory and caller factory' do
          allow_any_instance_of(QA::Factory::Base).to receive(:fabricate!).and_return(factory)
          allow(QA::Factory::Product).to receive(:populate!).and_return(spy('any'))

          subject.build!

          expect(block).to have_received(:call).with(an_instance_of(QA::Factory::Base), factory)
        end
      end
    end
  end
end
