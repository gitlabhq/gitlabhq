# frozen_string_literal: true

require 'spec_helper'

# Integration test that exports a file using the Import/Export feature
# It looks up for any sensitive word inside the JSON, so if a sensitive word is found
# we'll have to either include it adding the model that includes it to the +safe_list+
# or make sure the attribute is denylisted in the +import_export.yml+ configuration
RSpec.describe 'Import/Export - project export integration test', :js, feature_category: :importers do
  include ExportFileHelper

  let(:user) { create(:admin) }
  let(:export_path) { "#{Dir.tmpdir}/import_file_spec" }
  let(:sensitive_words) { %w[pass secret token key encrypted html] }
  let(:safe_list) do
    {
      token: [ProjectHook, Ci::Trigger, CommitStatus],
      key: [Project, Ci::Variable, :yaml_variables]
    }
  end

  let(:safe_hashes) do
    { yaml_variables: %w[key value public] }
  end

  let(:project) { setup_project }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'admin user' do
    before do
      sign_in(user)

      # Now that we export project in batches we produce more queries than before
      # needing to increase the default threshold
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(200)
    end

    it 'exports a project successfully', :sidekiq_inline do
      export_project_and_download_file(page, project, user)

      in_directory_with_expanded_export(project, user) do |exit_status, tmpdir|
        expect(exit_status).to eq(0)

        project_json_path = File.join(tmpdir, 'tree', 'project.json')
        expect(File).to exist(project_json_path)

        relations = []
        relations << Gitlab::Json.parse(File.read(project_json_path))
        Dir.glob(File.join(tmpdir, 'tree/project', '*.ndjson')) do |rb_filename|
          File.foreach(rb_filename) do |line|
            relations << Gitlab::Json.parse(line)
          end
        end

        relations.each do |relation_hash|
          sensitive_words.each do |sensitive_word|
            found = find_sensitive_attributes(sensitive_word, relation_hash)

            expect(found).to be_nil, failure_message(found.try(:key_found), found.try(:parent), sensitive_word)
          end
        end
      end
    end
  end

  def export_project_and_download_file(page, project, user)
    visit edit_project_path(project)

    expect(page).to have_content('Export project')

    find(:link, 'Export project').send_keys(:return)

    visit edit_project_path(project)

    expect(page).to have_content('Download export')
    expect(project.export_status(user)).to eq(:finished)
    expect(project.export_file(user).path).to include('tar.gz')
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
