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
end
