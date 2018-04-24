class RepositoryArchiveCleanUpService
  LAST_MODIFIED_TIME_IN_MINUTES = 120

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
    run(%W(find #{path} -not -path #{path} -type f \( -name \*.tar -o -name \*.bz2 -o -name \*.tar.gz -o -name \*.zip \) -maxdepth 2 -mmin +#{mmin} -delete))
  end

  def clean_up_empty_directories
    run(%W(find #{path} -not -path #{path} -type d -empty -name \*.git -maxdepth 1 -delete))
  end

  def run(cmd)
    Gitlab::Popen.popen(cmd)
  end
end
