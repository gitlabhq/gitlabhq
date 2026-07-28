# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for ServiceDeskSetting', feature_category: :cell do
  let_it_be(:project) { create(:project) }
  let(:custom_email) { FFaker::Internet.email }

  subject! { build(:service_desk_setting, project: project, custom_email: custom_email, project_key: 'key1') }

  it_behaves_like 'creating new claims'

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { custom_email: "updated#{subject.custom_email}" } }
  end

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) do
      { project_key: 'new_key', project_key_address_slug: "#{project.full_path_slug}-new_key" }
    end
  end

  it_behaves_like 'deleting existing claims'

  context 'when only custom_email is present' do
    subject! { build(:service_desk_setting, project: project, custom_email: custom_email) }

    it_behaves_like 'creating new claims'
    it_behaves_like 'deleting existing claims'
  end

  context 'when only project_key is present' do
    subject! { build(:service_desk_setting, project: project, project_key: 'key1') }

    it_behaves_like 'creating new claims'
    it_behaves_like 'deleting existing claims'
  end

  context 'when project_key_address_slug claims feature is disabled' do
    subject! { build(:service_desk_setting, project: project, project_key: 'key1') }

    before do
      stub_feature_flags(cells_claims_service_desk_settings_project_key_address_slugs: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
