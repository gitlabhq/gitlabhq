# frozen_string_literal: true

# RepositoryArchiveCleanUpService removes cached repository archives
# that are generated on-the-fly by Gitaly. These files are stored in the
# following form (as defined in lib/gitlab/git/repository.rb) and served
# by GitLab Workhorse:
#
# /path/to/repository/downloads/project-N/sha/@v2/archive.format
#
# Legacy paths omit the @v2 prefix.
#
# For example:
#
# /var/opt/gitlab/gitlab-rails/shared/cache/archive/project-1/master/@v2/archive.zip
class RepositoryArchiveCleanUpService
  LAST_MODIFIED_TIME_IN_MINUTES = 120

  # For `/path/project-N/sha/@v2/archive.zip`, `find /path -maxdepth 4` will find this file
  MAX_ARCHIVE_DEPTH = 4

  attr_reader :mmin, :path

  def initialize(mmin = LAST_MODIFIED_TIME_IN_MINUTES)
    @mmin = mmin
    @path = Gitlab.config.gitlab.repository_downloads_path
  end

  def execute
    Gitlab::Metrics.measure(:repository_archive_clean_up) do
      next unless File.directory?(path)

      clean_up_old_archives
      clean_up_empty_directories
    end
  end

  private

  def clean_up_old_archives
    run(%W[find #{path} -mindepth 1 -maxdepth #{MAX_ARCHIVE_DEPTH} -type f \( -name \*.tar -o -name \*.bz2 -o -name \*.tar.gz -o -name \*.zip \) -mmin +#{mmin} -delete])
  end

  def clean_up_empty_directories
    (1...MAX_ARCHIVE_DEPTH).reverse_each { |depth| clean_up_empty_directories_with_depth(depth) }
  end

  def clean_up_empty_directories_with_depth(depth)
    run(%W[find #{path} -mindepth #{depth} -maxdepth #{depth} -type d -empty -delete])
  end

  def run(cmd)
    Gitlab::Popen.popen(cmd)
  end
end
