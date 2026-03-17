# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::ServerVariable do
  describe '#to_h' do
    context 'with all parameters' do
      subject(:server_variable) do
        described_class.new(
          default: 'gitlab.com',
          description: 'Your GitLab instance hostname',
          enum: %w[gitlab.com gitlab.example.com]
        )
      end

      it 'returns a hash representation with all fields' do
        expect(server_variable.to_h).to eq({
          default: 'gitlab.com',
          description: 'Your GitLab instance hostname',
          enum: %w[gitlab.com gitlab.example.com]
        })
      end
    end

    context 'with only required parameters' do
      subject(:server_variable) { described_class.new(default: 'gitlab.com') }

      it 'returns a hash with only the default' do
        expect(server_variable.to_h).to eq({ default: 'gitlab.com' })
      end
    end

    context 'with default and description' do
      subject(:server_variable) do
        described_class.new(
          default: 'gitlab.com',
          description: 'Your GitLab instance hostname'
        )
      end

      it 'returns a hash with default and description' do
        expect(server_variable.to_h).to eq({
          default: 'gitlab.com',
          description: 'Your GitLab instance hostname'
        })
      end
    end
  end
end
