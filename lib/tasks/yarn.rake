# frozen_string_literal: true

namespace :yarn do
  desc 'Ensure Yarn is installed'
  task :available do
    unless system('yarn --version', out: File::NULL)
      warn(
        Rainbow('Error: Yarn executable was not detected in the system.').red,
        Rainbow('Download Yarn at https://yarnpkg.com/en/docs/install').green
      )
      abort
    end
  end

  desc 'Ensure Node dependencies are installed'
  task check: ['yarn:available'] do
    unless system('yarn check --ignore-engines', out: File::NULL)
      warn(
        Rainbow('Error: You have unmet dependencies. (`yarn check` command failed)').red,
        Rainbow('Run `yarn install` to install missing modules.').green
      )
      abort
    end
  end

  desc 'Install Node dependencies with Yarn'
  task install: ['yarn:available'] do
    unless system('yarn install --pure-lockfile --ignore-engines --prefer-offline')
      abort Rainbow('Error: Unable to install node modules.').red
    end
  end

  desc 'Remove Node dependencies'
  task :clobber do
    warn Rainbow('Purging ./node_modules directory').red
    FileUtils.rm_rf 'node_modules'
  end
end

desc 'Install Node dependencies with Yarn'
task yarn: ['yarn:install']
