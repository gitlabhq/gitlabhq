# frozen_string_literal: true

class TestContext < Gitlab::Backup::Cli::Context::SourceContext
  def gitlab_basepath
    test_helpers.spec_path.join('../../..')
  end

  def backup_basedir
    test_helpers.temp_path.join('backups')
  end

  private

  def test_helpers
    Class.new.extend(GitlabBackupHelpers)
  end
end
