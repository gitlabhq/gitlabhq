# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InProductGuidanceEnvironmentsWebideExperiment, :experiment do
  subject { described_class.new(project: project) }

  let(:project) { create(:project, :repository) }

  before do
    stub_experiments(in_product_guidance_environments_webide: :candidate)
  end

  it 'excludes projects with environments' do
    create(:environment, project: project)
    expect(subject).to exclude(project: project)
  end

  it 'does not exlude projects without environments' do
    expect(subject).not_to exclude(project: project)
  end
end
