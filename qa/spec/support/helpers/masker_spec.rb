# frozen_string_literal: true

module QA
  RSpec.describe QA::Support::Helpers::Masker do
    let(:secrets) { [:secret_content, 'secret'] }
    let(:content) do
      {
        numeric_content: 1,
        secret_content: 'a-private-token',
        public_content: 'gitlab',
        array_content: ['secret', :foo],
        private: 'hide me',
        hash_content: {
          secret: 'a-private-key',
          public: 'gitlab',
          array: ['secret', :bar],
          hash: { foo: 'secret' }
        }
      }
    end

    subject { described_class.new(by_key: secrets).mask(content) }

    shared_examples 'masks secrets' do
      it 'masks secrets' do
        expect(subject).to match(a_hash_including(expected))
      end
    end

    describe '.mask' do
      it 'instantiates an object and calls the mask instance method' do
        instance = instance_double('QA::Support::Helpers::Masker')

        expect(described_class).to receive(:new)
          .with(by_key: secrets, by_value: nil, mask: nil)
          .and_return(instance)
        expect(instance).to receive(:mask).with(content)

        described_class.mask(content, by_key: secrets, by_value: nil, mask: nil)
      end
    end

    describe '#initialize' do
      it 'requires by_key or by_key' do
        expect { described_class.new }.to raise_error(ArgumentError, /Please specify `by_key` or `by_value`/)
      end
    end

    describe '#mask' do
      context 'when content is blank' do
        let(:content) { [] }

        it 'returns content' do
          expect(subject).to match([])
        end
      end

      context 'when masking by key' do
        subject { described_class.new(by_key: secrets).mask(content) }

        let(:secrets) { [:secret_content, 'secret'] }

        it 'masks secrets' do
          expect(subject).to match(a_hash_including({
            secret_content: '****',
            hash_content: {
              secret: '****',
              public: 'gitlab',
              array: ['secret', :bar],
              hash: { foo: 'secret' }
            }
          }))
        end

        it 'does not mask by value' do
          expect(subject).to match(a_hash_including({
            array_content: ['secret', :foo],
            hash_content: {
              secret: '****',
              public: 'gitlab',
              array: ['secret', :bar],
              hash: { foo: 'secret' }
            }
          }))
        end

        context 'with values that are not strings' do
          let(:secrets) { [:numeric_content] }
          let(:expected) { { numeric_content: '****' } }

          include_examples 'masks secrets'
        end

        context 'when by_key is not an array' do
          let(:secrets) { :secret_content }
          let(:expected) { { secret_content: '****' } }

          include_examples 'masks secrets'
        end
      end

      context 'when masking by value' do
        shared_examples 'does not mask' do
          it 'does not mask' do
            expect(subject).to eq(content)
          end
        end

        subject { described_class.new(by_value: secrets).mask(content) }

        let(:secrets) { [:private, 'secret'] }

        it 'masks secrets' do
          expect(subject).to match(a_hash_including({
            secret_content: 'a-****-token',
            array_content: ['****', :foo],
            private: 'hide me',
            hash_content: {
              secret: 'a-****-key',
              public: 'gitlab',
              array: ['****', :bar],
              hash: { foo: '****' }
            }
          }))
        end

        it 'does not mask by key' do
          expect(subject).to match(a_hash_including(private: 'hide me'))
          expect(subject.fetch(:hash_content)).to match(a_hash_including(secret: 'a-****-key'))
        end

        context 'when content is an Array' do
          let(:content) { %w[secret not-secret] }

          it 'masks secrets' do
            expect(subject).to match_array(%w[**** not-****])
          end
        end

        context 'when content is a String' do
          let(:content) { 'secret' }
          let(:expected) { '****' }

          it 'masks secret values' do
            expect(subject).to eq(expected)
          end
        end

        context 'when content is an Integer' do
          let(:content) { 1 }

          include_examples 'does not mask'
        end

        context 'when content is a Float' do
          let(:content) { 1.0 }

          include_examples 'does not mask'
        end

        context 'when content is a Boolean' do
          let(:content) { false }

          include_examples 'does not mask'
        end
      end
    end
  end
end
