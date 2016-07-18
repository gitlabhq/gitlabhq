class RepositoryArchiveCleanUpService
  ALLOWED_ARCHIVE_EXTENSIONS = %w[tar tar.bz2 tar.gz zip].join(',').freeze
  LAST_MODIFIED_TIME_IN_MINUTES = 120

  def initialize(mmin = LAST_MODIFIED_TIME_IN_MINUTES)
    @mmin = mmin
    @path = Gitlab.config.gitlab.repository_downloads_path
  end

  def execute
    Gitlab::Metrics.measure(:repository_archive_clean_up) do
      return unless File.directory?(path)

      clean_up_old_archives
      clean_up_empty_directories
    end
  end

  private

  attr_reader :mmin, :path

  def clean_up_old_archives
    Dir.glob("#{path}/**.git/*{#{ALLOWED_ARCHIVE_EXTENSIONS}}") do |filename|
      File.delete(filename) if older?(filename)
    end
  end

  def older?(filename)
    File.exist?(filename) && File.new(filename).mtime < (Time.now - mmin * 60)
  end

  def clean_up_empty_directories
    Dir.glob("#{path}/**.git/").reverse_each do |dir|
      Dir.rmdir(dir) if empty?(dir)
    end
  end

  def empty?(dir)
    (Dir.entries(dir) - %w[. ..]).empty?
  end
end
