# frozen_string_literal: true

namespace :gitlab do
  namespace :keep_around do
    desc "GitLab | Keep-around | Find all orphaned keep-around references for a project"
    task orphaned: :gitlab_environment do
      warn_user_is_not_gitlab

      project = find_project

      unless project
        logger.info Rainbow("Specify the project with PROJECT_ID={number} or PROJECT_PATH={namespace/project-name}").red
        exit
      end

      create_csv do |csv|
        logger.info "Finding keep-around references..."

        project.repository.raw.list_refs(
          ["refs/#{::Repository::REF_KEEP_AROUND}/"],
          dynamic_timeout: ::Gitlab::GitalyClient.long_timeout
        ).each do |ref|
          csv << ['keep', ref.target, '']
        end

        add_pipeline_shas(project, csv)
        add_merge_request_shas(project, csv)
        add_merge_request_diff_shas(project, csv)
        add_note_shas(project, csv)

        logger.info "Keep-around orphan report complete"
      end
    end

    def add_pipeline_shas(project, csv)
      logger.info "Checking pipeline shas..."
      project.all_pipelines.select(:id, :sha, :before_sha).find_each do |pipeline|
        add_match(csv, pipeline.sha, ::Ci::Pipeline.name)
        # before_sha has a project fallback to produce a blank sha. For this
        # purpose we would prefer not to load project so we are loading the
        # attribute directly.
        add_match(csv, pipeline.read_attribute(:before_sha), ::Ci::Pipeline.name)
      end
    end

    def add_merge_request_shas(project, csv)
      logger.info "Checking merge request shas..."
      merge_requests = MergeRequest.of_projects(project).select(:id, :merge_commit_sha)
      merge_requests.find_each do |merge_request|
        add_match(csv, merge_request.merge_commit_sha, MergeRequest.name)
      end
    end

    def add_merge_request_diff_shas(project, csv)
      logger.info "Checking merge request diff shas..."
      [project, project.forked_from_project].compact.each do |project|
        MergeRequestDiff.by_project_id(project).each_batch(of: 100) do |batch|
          batch.select(:id, :start_commit_sha, :head_commit_sha, :diff_type).each do |diff|
            next if diff.merge_head?

            add_match(csv, diff.start_commit_sha, MergeRequestDiff.name)
            add_match(csv, diff.head_commit_sha, MergeRequestDiff.name)
          end
        end
      end
    end

    def add_note_shas(project, csv)
      logger.info "Checking note shas..."
      logger.warn "System notes will not be included."
      Note.where(project: project).where('NOT system').each_batch(of: 1000) do |b|
        b.where.not(commit_id: nil).select(:commit_id).each do |note|
          add_match(csv, note.commit_id, Note.name)
        end
        b.where(type: DiffNote).select(:type, :position, :original_position).each do |note|
          note.shas.each do |sha|
            add_match(csv, sha, DiffNote.name)
          end
        end
      end
    end

    def add_match(csv, sha, source)
      return if !sha.present? || Gitlab::Git.blank_ref?(sha)

      csv << ['usage', sha, source]
    end

    def create_csv
      filename = ENV['FILENAME']

      unless filename
        logger.info Rainbow("Specify the CSV output file with FILENAME={path}").red
        exit
      end

      File.open(filename, "w") do |file|
        yield CSV.new(file, headers: %w[operation commit_id source], write_headers: true)
      end
    end

    def find_project
      if ENV['PROJECT_ID']
        Project.find_by_id(ENV['PROJECT_ID']&.to_i)
      elsif ENV['PROJECT_PATH']
        Project.find_by_full_path(ENV['PROJECT_PATH'])
      end
    end
  end
end
