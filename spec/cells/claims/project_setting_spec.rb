# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for ProjectSetting', feature_category: :cell do
  let_it_be(:project) { create(:project) }

  subject! { build(:project_setting, project: project, pages_unique_domain: 'example-abc123') }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { pages_unique_domain: "updated-#{subject.pages_unique_domain}" } }
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_project_settings_pages_unique_domains: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
