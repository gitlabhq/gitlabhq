require 'spec_helper'

feature 'Import/Export - project import integration test', :js do
  include Select2Helper

  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:export_path) { "#{Dir.tmpdir}/import_file_spec" }

  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    gitlab_sign_in(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'when selecting the namespace' do
    let(:user) { create(:admin) }
    let!(:namespace) { user.namespace }
    let(:project_path) { 'test-project-path' + SecureRandom.hex }

    context 'prefilled the path' do
      scenario 'user imports an exported project successfully' do
        visit new_project_path

        select2(namespace.id, from: '#project_namespace_id')
        fill_in :project_path, with: project_path, visible: true
        click_import_project_tab
        click_link 'GitLab export'

        expect(page).to have_content('Import an exported GitLab project')
        expect(URI.parse(current_url).query).to eq("namespace_id=#{namespace.id}&path=#{project_path}")
        expect(Gitlab::ImportExport).to receive(:import_upload_path).with(filename: /\A\h{32}\z/).and_call_original

        attach_file('file', file)
        click_on 'Import project'

        expect(Project.count).to eq(1)

        project = Project.last
        expect(project).not_to be_nil
        expect(project.description).to eq("Foo Bar")
        expect(project.issues).not_to be_empty
        expect(project.merge_requests).not_to be_empty
        expect(project_hook_exists?(project)).to be true
        expect(wiki_exists?(project)).to be true
        expect(project.import_status).to eq('finished')
      end
    end

    context 'path is not prefilled' do
      scenario 'user imports an exported project successfully' do
        visit new_project_path
        click_import_project_tab
        click_link 'GitLab export'

        fill_in :path, with: 'test-project-path', visible: true
        attach_file('file', file)

        expect { click_on 'Import project' }.to change { Project.count }.by(1)

        project = Project.last
        expect(project).not_to be_nil
        expect(page).to have_content("Project 'test-project-path' is being imported")
      end
    end
  end

  scenario 'invalid project' do
    project = create(:project, namespace: user.namespace)

    visit new_project_path

    select2(user.namespace.id, from: '#project_namespace_id')
    fill_in :project_path, with: project.name, visible: true
    click_import_project_tab
    click_link 'GitLab export'
    attach_file('file', file)
    click_on 'Import project'

    page.within('.flash-container') do
      expect(page).to have_content('Project could not be imported')
    end
  end

  def wiki_exists?(project)
    wiki = ProjectWiki.new(project)
    File.exist?(wiki.repository.path_to_repo) && !wiki.repository.empty?
  end

  def project_hook_exists?(project)
    Gitlab::Git::Hook.new('post-receive', project.repository.raw_repository).exists?
  end

  def click_import_project_tab
    find('#import-project-tab').click
  end
end
