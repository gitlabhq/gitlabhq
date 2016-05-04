require 'spec_helper'

feature 'project import', feature: true, js: true do
  include Select2Helper

  let(:user) { create(:admin) }
  let!(:namespace) { create(:namespace, name: "asd", owner: user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:export_path) { "#{Dir::tmpdir}/import_file_spec" }
  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    login_as(user)
  end

  after(:each) do
    FileUtils.rm_rf(export_path, secure: true)
  end

  scenario 'user imports an exported project successfully' do
    expect(Project.all.count).to be_zero

    visit new_project_path

    select2('2', from: '#project_namespace_id')
    fill_in :project_path, with:'test-project-path', visible: true
    click_link 'GitLab project'

    expect(page).to have_content('GitLab project export')
    expect(URI.parse(current_url).query).to eq('namespace_id=2&path=test-project-path')

    attach_file('file', file)

    click_on 'Continue to the next step' # import starts

    expect(Project.last).not_to be_nil
    expect(Project.last.issues).not_to be_empty
    expect(Project.last.repo_exists?).to be true
  end
end
