require 'spec_helper'

feature 'project export', feature: true, js: true do
  include Select2Helper
  include ExportFileHelper

  let(:user) { create(:admin) }
  let(:export_path) { "#{Dir::tmpdir}/import_file_spec" }

  let(:sensitive_words) { %w[pass secret token key] }
  let(:safe_hashes) do
    {
      token: [
        { # Triggers
          "id" => 1,
          "token" => "token",
          "project_id" => nil,
          "deleted_at" => nil,
          "gl_project_id" => project.id
        },
        { # Project hooks
          "id" => 1,
          "project_id" => project.id,
          "service_id" => nil,
          "push_events" => true,
          "issues_events" => false,
          "merge_requests_events" => false,
          "tag_push_events" => false,
          "note_events" => false,
          "enable_ssl_verification" => true,
          "build_events" => false,
          "wiki_page_events" => false,
          "pipeline_events" => false,
          "token" => "token"
        }
      ]
    }
  end

  let(:project) { setup_project }

  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'admin user' do
    before do
      login_as(user)
    end

    scenario 'exports a project successfully' do
      visit edit_namespace_project_path(project.namespace, project)

      expect(page).to have_content('Export project')

      click_link 'Export project'

      visit edit_namespace_project_path(project.namespace, project)

      expect(page).to have_content('Download export')

      in_directory_with_expanded_export(project) do |exit_status, tmpdir|
        expect(exit_status).to eq(0)

        project_json_path = File.join(tmpdir, 'project.json')
        expect(File).to exist(project_json_path)

        project_hash = JSON.parse(IO.read(project_json_path))

        sensitive_words.each do |sensitive_word|
          expect(has_sensitive_attributes?(sensitive_word, project_hash)).to be false
        end
      end
    end
  end
end
