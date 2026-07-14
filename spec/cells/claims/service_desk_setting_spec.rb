# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for ServiceDeskSetting', feature_category: :cell do
  let_it_be(:project) { create(:project) }
  let(:custom_email) { FFaker::Internet.email }

  subject! { build(:service_desk_setting, project: project, custom_email: custom_email) }

  it_behaves_like 'creating new claims'

  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { custom_email: "updated#{subject.custom_email}" } }
  end

  it_behaves_like 'deleting existing claims'
end
