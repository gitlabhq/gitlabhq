require 'spec_helper'

describe 'Packages' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:package) { create(:maven_package, project: project) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  context 'when there are no packages' do
    it 'shows no packages message' do
      visit_project_packages

      expect(page).to have_content 'No packages stored for this project.'
    end
  end

  context 'when there are packages' do
    before do
      package

      visit_project_packages
    end

    it 'shows list of packages' do
      expect(page).to have_content(package.name)
      expect(page).to have_content(package.version)
    end

    it 'shows a single package' do
      click_on package.name

      expect(page).to have_content(package.name)
      expect(page).to have_content(package.version)

      package.package_files.each do |package_file|
        expect(page).to have_content(package_file.file_name)
      end
    end

    it 'removes package' do
      click_link 'Delete Package'

      expect(page).to have_content 'Package was removed'
      expect(page).not_to have_content(package.name)
    end
  end

  def visit_project_packages
    visit project_packages_path(project)
  end
end
