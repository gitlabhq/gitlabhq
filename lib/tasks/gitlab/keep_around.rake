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
          csv << ['keep', ref.target]
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
        add_match(csv, pipeline.sha)
        # before_sha has a project fallback to produce a blank sha. For this
        # purpose we would prefer not to load project so we are loading the
        # attribute directly.
        add_match(csv, pipeline.read_attribute(:before_sha))
      end
    end

    def add_merge_request_shas(project, csv)
      logger.info "Checking merge request shas..."
      merge_requests = MergeRequest.of_projects(project).select(:id, :merge_commit_sha)
      merge_requests.find_each do |merge_request|
        add_match(csv, merge_request.merge_commit_sha)
      end
    end

    def add_merge_request_diff_shas(project, csv)
      logger.info "Checking merge request diff shas..."
      merge_request_diffs = MergeRequestDiff
        .joins(:merge_request).merge(MergeRequest.of_projects([project, project.forked_from_project].compact))
        .select(:id, :start_commit_sha, :head_commit_sha, :diff_type)
      merge_request_diffs.find_each do |diff|
        next if diff.merge_head?

        add_match(csv, diff.start_commit_sha)
        add_match(csv, diff.head_commit_sha)
      end
    end

    def add_note_shas(project, csv)
      logger.info "Checking note shas..."
      logger.warn "System notes will not be included."
      Note.where(project: project).where('NOT system').each_batch(of: 1000) do |b|
        b.where.not(commit_id: nil).select(:commit_id).each do |note|
          add_match(csv, note.commit_id)
        end
        b.where(type: DiffNote).select(:type, :position, :original_position).each do |note|
          note.shas.each do |sha|
            add_match(csv, sha)
          end
        end
      end
    end

    def add_match(csv, sha)
      return if !sha.present? || Gitlab::Git.blank_ref?(sha)

      csv << ['usage', sha]
    end

    def create_csv
      filename = ENV['FILENAME']

      unless filename
        logger.info Rainbow("Specify the CSV output file with FILENAME={path}").red
        exit
      end

      File.open(filename, "w") do |file|
        yield CSV.new(file, headers: %w[operation commit_id], write_headers: true)
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
