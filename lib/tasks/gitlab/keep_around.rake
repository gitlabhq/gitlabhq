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

        refs = project.repository.raw.list_refs(
          ["refs/#{::Repository::REF_KEEP_AROUND}/"],
          dynamic_timeout: ::Gitlab::GitalyClient.long_timeout
        ).each_with_object({}) do |ref, memo|
          memo[ref.target] = {
            keep_around: ref.name,
            count: 0
          }
        end

        logger.info "Found #{refs.count} keep-around references"

        add_pipeline_shas(project, refs)
        add_merge_request_shas(project, refs)
        add_merge_request_diff_shas(project, refs)
        add_note_shas(project, refs)
        add_sent_notification_shas(project, refs)
        add_todo_shas(project, refs)

        logger.info "Summary:"
        logger.info "\tKeep-around references: #{refs.count}"
        logger.info "\tPotentially orphaned: #{refs.values.count { |ref| ref[:count] < 1 }}"

        logger.info "Writing CSV..."
        refs.each_value do |ref|
          csv << [ref[:keep_around], ref[:count]]
        end
        logger.info "Keep-around orphan report complete"
      end
    end

    def add_pipeline_shas(project, refs)
      logger.info "Checking pipeline shas..."
      project.all_pipelines.select(:id, :sha, :before_sha).find_each do |pipeline|
        add_match(refs, pipeline.sha)
        # before_sha has a project fallback to produce a blank sha. For this
        # purpose we would prefer not to load project so we are loading the
        # attribute directly.
        add_match(refs, pipeline.read_attribute(:before_sha))
      end
    end

    def add_merge_request_shas(project, refs)
      logger.info "Checking merge request shas..."
      merge_requests = MergeRequest.from_and_to_forks(project).select(:id, :merge_commit_sha)
      merge_requests.find_each do |merge_request|
        add_match(refs, merge_request.merge_commit_sha)
      end
    end

    def add_merge_request_diff_shas(project, refs)
      logger.info "Checking merge request diff shas..."
      merge_requests = MergeRequest.from_and_to_forks(project)
      merge_request_diffs = MergeRequestDiff
        .joins(:merge_request).merge(merge_requests)
        .select(:id, :start_commit_sha, :head_commit_sha, :base_commit_sha)

      merge_request_diffs.find_each do |diff|
        add_match(refs, diff.start_commit_sha)
        add_match(refs, diff.head_commit_sha)
        add_match(refs, diff.base_commit_sha)
      end
    end

    def add_note_shas(project, refs)
      logger.info "Checking note shas..."
      logger.warn "System notes will not be included."
      Note.where(project: project).where('NOT system').each_batch(of: 1000) do |b|
        b.where.not(commit_id: nil).select(:commit_id).each do |note|
          add_match(refs, note.commit_id)
        end
        b.where(type: DiffNote).select(:type, :position, :original_position).each do |note|
          note.shas.each do |sha|
            add_match(refs, sha)
          end
        end
      end
    end

    def add_sent_notification_shas(_project, _refs)
      logger.warn "Sent notifications will not be included."
    end

    def add_todo_shas(project, refs)
      logger.info "Checking todo shas..."
      Todo.where(project: project).each_batch(of: 1000) do |b|
        b.where.not(commit_id: nil).select(:commit_id).each do |todo|
          add_match(refs, todo.commit_id)
        end
      end
    end

    def add_match(refs, sha)
      return unless refs[sha]

      refs[sha][:count] += 1
    end

    def create_csv
      filename = ENV['FILENAME']

      unless filename
        logger.info Rainbow("Specify the CSV output file with FILENAME={path}").red
        exit
      end

      File.open(filename, "w") do |file|
        yield CSV.new(file, headers: %w[keep_around count], write_headers: true)
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
