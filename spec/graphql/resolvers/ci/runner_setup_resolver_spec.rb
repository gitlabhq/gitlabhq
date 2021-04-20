# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerSetupResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let(:user) { create(:user) }

    subject(:resolve_subject) { resolve(described_class, ctx: { current_user: user }, args: { platform: platform, architecture: 'amd64' }) }

    context 'with container platforms' do
      let(:platform) { 'docker' }
      let(:project) { create(:project) }

      it 'returns install instructions' do
        expect(resolve_subject[:install_instructions]).not_to eq(nil)
      end

      it 'does not return register instructions' do
        expect(resolve_subject[:register_instructions]).to eq(nil)
      end
    end

    context 'with regular platforms' do
      let(:platform) { 'linux' }

      it 'returns install and register instructions' do
        expect(resolve_subject.keys).to contain_exactly(:install_instructions, :register_instructions)
        expect(resolve_subject.values).not_to include(nil)
      end
    end
  end
end
