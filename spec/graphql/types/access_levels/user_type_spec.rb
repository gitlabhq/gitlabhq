# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelUser'], feature_category: :source_code_management do
  include GraphqlHelpers

  describe 'config' do
    subject { described_class }

    let(:expected_fields) { %w[id username name publicEmail avatarUrl webUrl webPath] }

    it { is_expected.to require_graphql_authorizations(:read_user) }
    it { is_expected.to have_graphql_fields(expected_fields).only }
  end

  describe 'fields' do
    let(:object) { instance_double(User) }
    let(:current_user) { instance_double(User) }

    before do
      allow(described_class).to receive(:authorized?).and_return(true)
    end

    describe '#name' do
      it 'calls User#redacted_name(current_user)' do
        allow(object).to receive(:redacted_name).with(current_user)
        resolve_field(:name, object, current_user: current_user)
        expect(object).to have_received(:redacted_name).with(current_user).once
      end
    end

    describe '#avatar_url' do
      it 'calls User#avatar_url(only_path: false)' do
        allow(object).to receive(:avatar_url).with(only_path: false)
        resolve_field(:avatar_url, object, current_user: current_user)
        expect(object).to have_received(:avatar_url).with(only_path: false).once
      end
    end
  end
end
