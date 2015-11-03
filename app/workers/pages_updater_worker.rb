class PagesUpdaterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :pages

  def perform(build_id)
    @build_id = build_id
    return unless valid?

    FileUtils.mkdir_p(tmp_path)

    Dir.mktmpdir(nil, tmp_path) do |dir|
      cmd = %W(tar -zxf #{build.artifact_file.path} -C #{dir})
      return unless system(*cmd)
      return unless valid?

      public_dir = File.join(dir, 'public')
      return unless File.exists?(public_dir)

      FileUtils.mkdir_p(pages_path)
      if File.exists?(pages_path)
        FileUtils.move(pages_path, old_pages_path)
      end
      FileUtils.move(public_dir, pages_path)
      FileUtils.rm_r(old_pages_path)
    end
  end

  private

  def valid?
    # check if ref is still recent one
    build && build.artifact_file? && build.sha == gl_project.commit.sha
  end

  def build
    @build ||= Ci::Build.find(@build_id)
  end

  def gl_project
    @gl_project ||= build.gl_project
  end

  def tmp_path
    @tmp_path ||= File.join(Settings.gitlab_ci.pages_path, 'tmp')
  end

  def pages_path
    @pages_path ||= File.join(Settings.gitlab_ci.pages_path, gl_project.path_with_namespace)
  end

  def old_pages_path
    @old_pages_path ||= File.expand_path("#{pages_path}.#{SecureRandom.hex}")
  end
end
