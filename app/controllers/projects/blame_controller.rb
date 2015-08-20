# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)
    @blame = group_blame_lines
  end

  def group_blame_lines
    blame = Gitlab::Git::Blame.new(@repository, @commit.id, @path)

    prev_sha = nil
    groups = []
    current_group = nil

    blame.each do |commit, line|
      if prev_sha && prev_sha == commit.sha
        current_group[:lines] << line
      else
        groups << current_group if current_group.present?
        current_group = { commit: commit, lines: [line] }
      end

      prev_sha = commit.sha
    end

    groups << current_group if current_group.present?
    groups
  end
end
