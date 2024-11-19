# frozen_string_literal: true

RSpec.shared_examples "context exposing all common configuration methods" do
  let(:fake_gitlab_basepath) { Pathname.new(Dir.mktmpdir('gitlab', temp_path)) }

  before do
    allow(context).to receive(:gitlab_basepath).and_return(fake_gitlab_basepath)
    FileUtils.mkdir fake_gitlab_basepath.join('config')
  end

  after do
    fake_gitlab_basepath.rmtree
  end

  describe '#gitlab_version' do
    it 'returns the GitLab version from the VERSION file' do
      version_fixture = fixtures_path.join('VERSION')
      FileUtils.copy(version_fixture, fake_gitlab_basepath)

      expect(context.gitlab_version).to eq('17.0.3-ee')
    end
  end

  describe '#backup_basedir' do
    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.backup_basedir).to eq(fake_gitlab_basepath.join('tmp/tests/backups'))
      end
    end

    context 'with full path configure in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.backup_basedir).to eq(Pathname('/tmp/gitlab/full/backups'))
      end
    end
  end

  describe '#ci_builds_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.ci_builds_path).to eq(fake_gitlab_basepath.join('builds'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.ci_builds_path).to eq(fake_gitlab_basepath.join('tests/builds'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.ci_builds_path).to eq(Pathname('/tmp/gitlab/full/builds'))
      end
    end
  end

  describe '#ci_jobs_artifacts_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.ci_job_artifacts_path).to eq(fake_gitlab_basepath.join('test-shared/artifacts'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.ci_job_artifacts_path).to eq(fake_gitlab_basepath.join('tmp/tests/artifacts'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.ci_job_artifacts_path).to eq(Pathname('/tmp/gitlab/full/artifacts'))
      end
    end
  end

  describe '#ci_secure_files_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.ci_secure_files_path).to eq(fake_gitlab_basepath.join('test-shared/ci_secure_files'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.ci_secure_files_path).to eq(fake_gitlab_basepath.join('tmp/tests/ci_secure_files'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.ci_secure_files_path).to eq(Pathname('/tmp/gitlab/full/ci_secure_files'))
      end
    end
  end

  describe '#ci_lfs_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.ci_lfs_path).to eq(fake_gitlab_basepath.join('test-shared/lfs-objects'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.ci_lfs_path).to eq(fake_gitlab_basepath.join('tmp/tests/lfs-objects'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.ci_lfs_path).to eq(Pathname('/tmp/gitlab/full/lfs-objects'))
      end
    end
  end

  describe '#packages_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.packages_path).to eq(fake_gitlab_basepath.join('test-shared/packages'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.packages_path).to eq(fake_gitlab_basepath.join('tmp/tests/packages'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.packages_path).to eq(Pathname('/tmp/gitlab/full/packages'))
      end
    end
  end

  describe '#pages_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.pages_path).to eq(fake_gitlab_basepath.join('test-shared/pages'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.pages_path).to eq(fake_gitlab_basepath.join('tmp/tests/pages'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.pages_path).to eq(Pathname('/tmp/gitlab/full/pages'))
      end
    end
  end

  describe '#registry_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.registry_path).to eq(fake_gitlab_basepath.join('test-shared/registry'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.registry_path).to eq(fake_gitlab_basepath.join('tmp/tests/registry'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.registry_path).to eq(Pathname('/tmp/gitlab/full/registry'))
      end
    end
  end

  describe '#terraform_state_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.terraform_state_path).to eq(fake_gitlab_basepath.join('test-shared/terraform_state'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.terraform_state_path).to eq(fake_gitlab_basepath.join('tmp/tests/terraform_state'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.terraform_state_path).to eq(Pathname('/tmp/gitlab/full/terraform_state'))
      end
    end
  end

  describe '#upload_path' do
    context 'with a missing configuration value' do
      it 'returns the default value in full path' do
        use_gitlab_config_fixture('gitlab-missingconfigs.yml')

        expect(context.upload_path).to eq(fake_gitlab_basepath.join('public/uploads'))
      end
    end

    context 'with a relative path configured in gitlab.yml' do
      it 'returns a full path based on gitlab basepath' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.upload_path).to eq(fake_gitlab_basepath.join('tmp/tests/public/uploads'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.upload_path).to eq(Pathname('/tmp/gitlab/full/public/uploads'))
      end
    end
  end

  describe '#gitlab_shared_path' do
    context 'with shared path not configured in gitlab.yml' do
      it 'returns the default value' do
        use_gitlab_config_fixture('gitlab-empty.yml')

        expect(context.send(:gitlab_shared_path)).to eq(Pathname('shared'))
      end
    end

    context 'with shared path configured in gitlab.yml' do
      it 'returns a relative path' do
        use_gitlab_config_fixture('gitlab-relativepaths.yml')

        expect(context.send(:gitlab_shared_path)).to eq(Pathname('shared-tests'))
      end
    end

    context 'with a full path configured in gitlab.yml' do
      it 'returns a full path as configured in gitlab.yml' do
        use_gitlab_config_fixture('config/gitlab.yml')

        expect(context.send(:gitlab_shared_path)).to eq(Pathname('/tmp/gitlab/full/shared'))
      end
    end
  end

  def use_gitlab_config_fixture(fixture)
    gitlab_yml_fixture = fixtures_path.join(fixture)
    FileUtils.copy(gitlab_yml_fixture, fake_gitlab_basepath.join('config/gitlab.yml'))
  end
end
