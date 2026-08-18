# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EmailHandler::Target, feature_category: :service_desk do
  it 'builds a project_id target' do
    target = described_class.project_id(54)

    expect(target.kind).to eq(:project_id)
    expect(target.value).to eq(54)
  end

  it 'builds a namespace_id target' do
    expect(described_class.namespace_id(7)).to eq(described_class.new(kind: :namespace_id, value: 7))
  end

  it 'builds a route target' do
    expect(described_class.route('gitlab-org')).to eq(described_class.new(kind: :route, value: 'gitlab-org'))
  end

  it 'reduces a route target to its top-level namespace segment' do
    expect(described_class.route('gitlab-org/gitlab/subgroup')).to eq(described_class.route('gitlab-org'))
  end

  it 'builds a service_desk_custom_email target' do
    target = described_class.service_desk_custom_email('support@acme.com')

    expect(target.kind).to eq(:service_desk_custom_email)
    expect(target.value).to eq('support@acme.com')
  end

  it 'builds a service_desk_project_key_address_slug target' do
    target = described_class.service_desk_project_key_address_slug('gitlab-org-gitlab-ce-mykey_123')

    expect(target.kind).to eq(:service_desk_project_key_address_slug)
    expect(target.value).to eq('gitlab-org-gitlab-ce-mykey_123')
  end

  it 'compares equal by kind and value' do
    expect(described_class.project_id(1)).to eq(described_class.new(kind: :project_id, value: 1))
    expect(described_class.project_id(1)).not_to eq(described_class.project_id(2))
    expect(described_class.project_id(1)).not_to eq(described_class.namespace_id(1))
  end
end
