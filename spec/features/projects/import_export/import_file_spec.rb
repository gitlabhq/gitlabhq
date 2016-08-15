require 'spec_helper'

feature 'project import', feature: true, js: true do
  include Select2Helper

  let(:admin) { create(:admin) }
  let(:normal_user) { create(:user) }
  let!(:namespace) { create(:namespace, name: "asd", owner: admin) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:export_path) { "#{Dir::tmpdir}/import_file_spec" }
  let(:project) { Project.last }

  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
  end

  after(:each) do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'admin user' do
    before do
      login_as(admin)
    end

    scenario 'user imports an exported project successfully' do
      expect(Project.all.count).to be_zero

      visit new_project_path

      select2('2', from: '#project_namespace_id')
      fill_in :project_path, with: 'test-project-path', visible: true
      click_link 'GitLab export'

      expect(page).to have_content('GitLab project export')
      expect(URI.parse(current_url).query).to eq('namespace_id=2&path=test-project-path')

      attach_file('file', file)

      click_on 'Import project' # import starts

      expect(project).not_to be_nil
      expect(project.issues).not_to be_empty
      expect(project.merge_requests).not_to be_empty
      expect(wiki_exists?).to be true
      expect(project.import_status).to eq('finished')
    end
  end

  context 'normal user' do
    before do
      login_as(normal_user)
    end

    scenario 'non-admin user is not allowed to import a project' do
      expect(Project.all.count).to be_zero

      visit new_project_path

      fill_in :project_path, with: 'test-project-path', visible: true

      expect(page).not_to have_content('GitLab export')
    end
  end

  def wiki_exists?
    wiki = ProjectWiki.new(project)
    File.exist?(wiki.repository.path_to_repo) && !wiki.repository.empty?
  end
end
