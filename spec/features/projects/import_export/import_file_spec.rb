require 'spec_helper'

feature 'project import', feature: true, js: true do
  include Select2Helper

  let(:user) { create(:admin) }
  let!(:namespace) { create(:namespace, name: "asd", owner: user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }

  background do
    export_path = "#{Dir::tmpdir}/import_file_spec"
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    login_as(user)
  end

  scenario 'user imports an exported project successfully' do
    visit new_project_path

    select2('2', from: '#project_namespace_id')
    fill_in :project_path, with:'test-project-path', visible: true
    click_link 'GitLab project'

    expect(page).to have_content('GitLab export file')
    expect(URI.parse(current_url).query).to eq('namespace_id=2&path=test-project-path')
    attach_file('file', file)

    #TODO check timings

    sleep 1

    click_on 'Continue to the next step'
  end

  def drop_in_dropzone(file_path)
    # Generate a fake input selector
    page.execute_script <<-JS
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file'}
      ).appendTo('body');
    JS
    # Attach the file to the fake input selector with Capybara
    attach_file("fakeFileInput", file_path)
    # Add the file to a fileList array and trigger the fake drop event
    page.execute_script <<-JS
      var fileList = [$('#fakeFileInput')[0].files[0]];
      var e = jQuery.Event('drop', { dataTransfer : { files : fileList } });
      $('.div-dropzone')[0].dropzone.listeners[0].events.drop(e);
    JS
  end
end
