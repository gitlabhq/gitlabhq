require 'spec_helper'

feature 'project export', feature: true, js: true do
  include Select2Helper

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
          "gl_project_id" => 4
        },
        { # Project hooks
          "id" => 1,
          "project_id" => 4,
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

    scenario 'user imports an exported project successfully' do
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

  def setup_project
    issue = create(:issue, assignee: user)
    snippet = create(:project_snippet)
    release = create(:release)

    project = create(:project,
                     :public,
                     issues: [issue],
                     snippets: [snippet],
                     releases: [release]
                    )
    label = create(:label, project: project)
    create(:label_link, label: label, target: issue)
    milestone = create(:milestone, project: project)
    merge_request = create(:merge_request, source_project: project, milestone: milestone)
    commit_status = create(:commit_status, project: project)

    ci_pipeline = create(:ci_pipeline,
                         project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch,
                         statuses: [commit_status])

    create(:ci_build, pipeline: ci_pipeline, project: project)
    create(:milestone, project: project)
    create(:note, noteable: issue, project: project)
    create(:note, noteable: merge_request, project: project)
    create(:note, noteable: snippet, project: project)
    create(:note_on_commit,
           author: user,
           project: project,
           commit_id: ci_pipeline.sha)

    create(:event, target: milestone, project: project, action: Event::CREATED, author: user)
    create(:project_member, :master, user: user, project: project)
    create(:ci_variable, project: project)
    create(:ci_trigger, project: project)
    key = create(:deploy_key)
    key.projects << project
    create(:service, project: project)
    create(:project_hook, project: project, token: 'token')
    create(:protected_branch, project: project)

    project
  end

  # Expands the compressed file for an exported project into +tmpdir+
  def in_directory_with_expanded_export(project)
    Dir.mktmpdir do |tmpdir|
      export_file = project.export_project_path
      _output, exit_status = Gitlab::Popen.popen(%W{tar -zxf #{export_file} -C #{tmpdir}})

      yield(exit_status, tmpdir)
    end
  end

  # Recursively finds key/values including +key+ as part of the key, inside a nested hash
  def deep_find_with_parent(key, object, found = nil)
    if object.respond_to?(:key?) && object.keys.any? { |k| k.include?(key) }
      [object[key], object] if object[key]
    elsif object.is_a? Enumerable
      object.find { |*a| found, object = deep_find_with_parent(key, a.last, found) }
      [found, object] if found
    end
  end

  # Returns true if a sensitive word is found inside a hash, excluding safe hashes
  def has_sensitive_attributes?(sensitive_word, project_hash)
    loop do
      object, parent = deep_find_with_parent(sensitive_word, project_hash)
      parent.except!('created_at', 'updated_at', 'url') if parent

      if object && safe_hashes[sensitive_word.to_sym].include?(parent)
        # It's in the safe list, remove hash and keep looking
        parent.delete(object)
      elsif object
        return true
      else
        return false
      end
    end
  end
end
