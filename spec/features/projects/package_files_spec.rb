# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PackageFiles', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:package) { create(:maven_package, project: project) }
  let!(:package_file) { package.package_files.first }

  before do
    sign_in(user)
  end

  context 'user with master role' do
    before do
      project.add_maintainer(user)
    end

    it 'allows direct download by url' do
      visit download_project_package_file_path(project, package_file)

      expect(status_code).to eq(200)
    end

    it 'does not allow download of package belonging to different project' do
      another_package = create(:maven_package)
      another_file = another_package.package_files.first

      visit download_project_package_file_path(project, another_file)

      expect(status_code).to eq(404)
    end
  end

  it 'does not allow direct download when no access to the project' do
    visit download_project_package_file_path(project, package_file)

    expect(status_code).to eq(404)
  end

  it 'gives 404 when no package file exist' do
    visit download_project_package_file_path(project, non_existing_record_id)

    expect(status_code).to eq(404)
  end
end
