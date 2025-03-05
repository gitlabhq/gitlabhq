# frozen_string_literal: true

class TestContext < Gitlab::Backup::Cli::Context::SourceContext
  def gitlab_basepath
    @gitlab_basepath ||= Pathname(Dir.mktmpdir('gitlab', test_helpers.temp_path))
  end

  def backup_basedir
    gitlab_basepath.join('backups')
  end

  def gitlab_original_basepath
    test_helpers.spec_path.join('../../..')
  end

  # Deletes the temporary folders
  def cleanup!
    dir_permissions = (File.stat(gitlab_basepath).mode & 0o777).to_s(8) # retrieve permissions in octal format)

    FileUtils.rm_rf(gitlab_basepath) if dir_permissions == "700" # ensure it's a temporary dir before deleting
  end

  private

  def test_helpers
    Class.new.extend(GitlabBackupHelpers)
  end
end
