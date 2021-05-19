# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users views raw design image files' do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue, versions_count: 2) }

  let(:newest_version) { design.versions.ordered.first }
  let(:oldest_version) { design.versions.ordered.last }

  before do
    enable_design_management
  end

  it 'serves the latest design version when no ref is given' do
    visit project_design_management_designs_raw_image_path(design.project, design)

    expect(response_headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to eq(
      workhorse_data_header_for_version(oldest_version.sha)
    )
  end

  it 'serves the correct design version when a ref is given' do
    visit project_design_management_designs_raw_image_path(design.project, design, oldest_version.sha)

    expect(response_headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to eq(
      workhorse_data_header_for_version(oldest_version.sha)
    )
  end

  private

  def workhorse_data_header_for_version(ref)
    blob = project.design_repository.blob_at(ref, design.full_path)

    Gitlab::Workhorse.send_git_blob(project.design_repository, blob).last
  end
end
