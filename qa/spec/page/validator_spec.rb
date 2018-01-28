describe QA::Page::Validator do
  describe '#constants' do
    subject do
      described_class.new(QA::Page::Project)
    end

    it 'returns all constants that are module children' do
      expect(subject.constants)
        .to include QA::Page::Project::New, QA::Page::Project::Settings
    end
  end

  describe '#descendants' do
    subject do
      described_class.new(QA::Page::Project)
    end

    it 'recursively returns all descendants that are page objects' do
      expect(subject.descendants)
        .to include QA::Page::Project::New, QA::Page::Project::Settings::Repository
    end

    it 'does not return modules that aggregate page objects' do
      expect(subject.descendants)
        .not_to include QA::Page::Project::Settings
    end
  end

  context 'when checking validation errors' do
    let(:view) { spy('view') }

    before do
      allow(QA::Page::Admin::Settings)
        .to receive(:views).and_return([view])
    end

    subject do
      described_class.new(QA::Page::Admin)
    end

    context 'when there are no validation errors' do
      before do
        allow(view).to receive(:errors).and_return([])
      end

      describe '#errors' do
        it 'does not return errors' do
          expect(subject.errors).to be_empty
        end
      end

      describe '#validate!' do
        it 'does not raise error' do
          expect { subject.validate! }.not_to raise_error
        end
      end
    end

    context 'when there are validation errors' do
      before do
        allow(view).to receive(:errors)
          .and_return(['some error', 'another error'])
      end

      describe '#errors' do
        it 'returns errors' do
          expect(subject.errors.count).to eq 2
        end
      end

      describe '#validate!' do
        it 'raises validation error' do
          expect { subject.validate! }
            .to raise_error described_class::ValidationError
        end
      end
    end
  end
end
