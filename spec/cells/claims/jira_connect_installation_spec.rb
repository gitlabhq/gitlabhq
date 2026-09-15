# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for JiraConnectInstallation', feature_category: :cell do
  subject! do
    build(:jira_connect_installation,
      forge_installation_xid: 'ari:cloud:ecosystem::installation/0a3a7799-53ae-4a5b-9e7e-03338980abb5')
  end

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) do
      { forge_installation_xid: 'ari:cloud:ecosystem::installation/8db33809-1f32-48bb-8c52-5877dab48107',
        client_key: subject.client_key.reverse }
    end
  end

  context 'without a forge_installation_xid (claims only client_key)' do
    subject! { build(:jira_connect_installation) }

    it_behaves_like 'creating new claims'
    it_behaves_like 'deleting existing claims'
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_jira_connect_installations: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
