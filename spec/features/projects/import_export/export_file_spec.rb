require 'spec_helper'

# Integration test that exports a file using the Import/Export feature
# It looks up for any sensitive word inside the JSON, so if a sensitive word is found
# we'll have to either include it adding the model that includes it to the +safe_list+
# or make sure the attribute is blacklisted in the +import_export.yml+ configuration
feature 'Import/Export - project export integration test', :js do
  include Select2Helper
  include ExportFileHelper

  let(:user) { create(:admin) }
  let(:export_path) { "#{Dir.tmpdir}/import_file_spec" }
  let(:config_hash) { YAML.load_file(Gitlab::ImportExport.config_file).deep_stringify_keys }

  let(:sensitive_words) { %w[pass secret token key] }
  let(:safe_list) do
    {
      token: [ProjectHook, Ci::Trigger, CommitStatus],
      key: [Project, Ci::Variable, :yaml_variables]
    }
  end
  let(:safe_hashes) { { yaml_variables: %w[key value public] } }

  let(:project) { setup_project }

  background do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'admin user' do
    before do
      sign_in(user)
    end

    scenario 'exports a project successfully' do
      visit edit_project_path(project)

      expect(page).to have_content('Export project')

      find(:link, 'Export project').send_keys(:return)

      visit edit_project_path(project)

      expect(page).to have_content('Download export')

      expect(file_permissions(project.export_path)).to eq(0700)

      in_directory_with_expanded_export(project) do |exit_status, tmpdir|
        expect(exit_status).to eq(0)

        project_json_path = File.join(tmpdir, 'project.json')
        expect(File).to exist(project_json_path)

        project_hash = JSON.parse(IO.read(project_json_path))

        sensitive_words.each do |sensitive_word|
          found = find_sensitive_attributes(sensitive_word, project_hash)

          expect(found).to be_nil, failure_message(found.try(:key_found), found.try(:parent), sensitive_word)
        end
      end
    end

    def failure_message(key_found, parent, sensitive_word)
      <<-MSG
        Found a new sensitive word <#{key_found}>, which is part of the hash #{parent.inspect}

        If you think this information shouldn't get exported, please exclude the model or attribute in IMPORT_EXPORT_CONFIG.

        Otherwise, please add the exception to +safe_list+ in CURRENT_SPEC using #{sensitive_word} as the key and the
        correspondent hash or model as the value.

        Also, if the attribute is a generated unique token, please add it to RelationFactory::TOKEN_RESET_MODELS if it needs to be
        reset (to prevent duplicate column problems while importing to the same instance).

        IMPORT_EXPORT_CONFIG: #{Gitlab::ImportExport.config_file}
        CURRENT_SPEC: #{__FILE__}
      MSG
    end
  end
end
