# frozen_string_literal: true

module QA
  RSpec.describe QA::Support::API do
    describe ".masked_parsed_response" do
      let(:secrets) { [:secret] }
      let(:response_to_test) do
        Struct.new(:body).new('{ "id": 1, "token": "foo", "secret": "bar", "name": "gitlab" }')
      end

      subject { described_class.masked_parsed_response(response_to_test, mask_secrets: secrets) }

      shared_examples 'masks secrets' do
        subject { described_class.masked_parsed_response(response_to_test, mask_secrets: secrets) }

        it 'masks secrets' do
          expect(subject).to match(a_hash_including(expected))
        end
      end

      shared_examples 'raises an error' do
        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError, /Expected response body to be a hash/)
        end
      end

      context 'when the response body is a hash' do
        context 'with secret strings' do
          let(:secrets) { [:token, :secret] }
          let(:expected) do
            {
              id: 1,
              token: '****',
              secret: '****',
              name: 'gitlab'
            }
          end

          include_examples 'masks secrets'
        end

        context 'with secrets that are not strings' do
          let(:secrets) { [:id] }
          let(:expected) { { id: '****' } }

          include_examples 'masks secrets'
        end
      end

      context 'when the response body is a String' do
        let(:response_to_test) { Struct.new(:body).new('"secret"') }

        include_examples 'raises an error'
      end

      context 'when the response body is an Array' do
        let(:response_to_test) { Struct.new(:body).new('["secret", "not-secret"]') }

        include_examples 'raises an error'
      end

      context 'when the response body is an Integer' do
        let(:response_to_test) { Struct.new(:body).new('1') }

        include_examples 'raises an error'
      end

      context 'when the response body is a Float' do
        let(:response_to_test) { Struct.new(:body).new('1.0') }

        include_examples 'raises an error'
      end

      context 'when the response body is a Boolean' do
        let(:response_to_test) { Struct.new(:body).new('true') }

        include_examples 'raises an error'
      end

      context 'when the response body is null' do
        let(:response_to_test) { Struct.new(:body).new('null') }

        include_examples 'raises an error'
      end

      context 'when mask_secrets is not an array' do
        let(:secrets) { 'secret' }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError, /Expected `mask_secrets` to be an array, got/)
        end
      end

      context 'when mask_secrets contents are not all symbols' do
        let(:secrets) { ['secret', :secret] }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError, /Expected `mask_secrets` to be an array of symbols/)
        end
      end
    end
  end
end
