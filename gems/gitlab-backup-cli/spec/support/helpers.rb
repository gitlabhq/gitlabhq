# frozen_string_literal: true

module GitlabBackupHelpers
  FakeContext = Struct.new(:gitlab_version, :backup_basedir, :env, keyword_init: true)

  # Specs basepath
  # @return [Pathname]
  def spec_path
    Pathname.new(__dir__).join('..').expand_path
  end

  # Fixtures basepath
  # @return [Pathname]
  def fixtures_path
    spec_path.join('fixtures')
  end

  # Temporary folder basepath inside project
  # @return [Pathname]
  def temp_path
    spec_path.join('..', 'tmp').expand_path
  end

  def stub_env(var, return_value)
    stub_const('ENV', ENV.to_hash.merge(var => return_value))
  end

  def build_fake_context
    FakeContext.new(
      gitlab_version: '16.10',
      backup_basedir: temp_path.join('backups'),
      env: ActiveSupport::EnvironmentInquirer.new('test')
    )
  end

  def build_test_context
    TestContext.new.tap do |context|
      # config/database.yml
      db = context.gitlab_original_basepath.join('config/database.yml')
      test_db = context.gitlab_basepath.join('config/database.yml')
      FileUtils.mkdir_p(File.dirname(test_db))
      FileUtils.copy(db, test_db)
      # config/gitlab.yml
      gitlab_cfg = fixtures_path.join('config/gitlab.yml')
      gitlab_cfg_path = context.gitlab_basepath.join('config/gitlab.yml')
      FileUtils.copy(gitlab_cfg, gitlab_cfg_path)

      # Mocked Rakefile and Gemfile
      FileUtils.cp_r(fixtures_path.join('gitlab_fake').glob('*'), context.gitlab_basepath)
    end
  end
end

RSpec.configure do |config|
  config.include GitlabBackupHelpers
  # from gitlab-rspec
  config.include NextInstanceOf
end
