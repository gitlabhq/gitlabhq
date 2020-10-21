# frozen_string_literal: true

RSpec.describe QA::Git::Location do
  describe '.new' do
    context 'when URI starts with ssh://' do
      context 'when URI has port' do
        it 'parses correctly' do
          uri = described_class
            .new('ssh://git@qa.test:2222/sandbox/qa/repo.git')

          expect(uri.user).to eq('git')
          expect(uri.host).to eq('qa.test')
          expect(uri.port).to eq(2222)
          expect(uri.path).to eq('/sandbox/qa/repo.git')
        end
      end

      context 'when URI does not have port' do
        it 'parses correctly' do
          uri = described_class
            .new('ssh://git@qa.test/sandbox/qa/repo.git')

          expect(uri.user).to eq('git')
          expect(uri.host).to eq('qa.test')
          expect(uri.port).to eq(22)
          expect(uri.path).to eq('/sandbox/qa/repo.git')
        end
      end
    end

    context 'when URI does not start with ssh://' do
      context 'when host does not have colons' do
        it 'parses correctly' do
          uri = described_class
            .new('git@qa.test:sandbox/qa/repo.git')

          expect(uri.user).to eq('git')
          expect(uri.host).to eq('qa.test')
          expect(uri.port).to eq(22)
          expect(uri.path).to eq('/sandbox/qa/repo.git')
        end
      end

      context 'when host has a colon' do
        it 'parses correctly' do
          uri = described_class
            .new('[git@qa:test]:sandbox/qa/repo.git')

          expect(uri.user).to eq('git')
          expect(uri.host).to eq('qa%3Atest')
          expect(uri.port).to eq(22)
          expect(uri.path).to eq('/sandbox/qa/repo.git')
        end
      end
    end
  end
end
