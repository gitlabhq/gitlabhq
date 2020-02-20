# frozen_string_literal: true

namespace :yarn do
  desc 'Ensure Yarn is installed'
  task :available do
    unless system('yarn --version', out: File::NULL)
      warn(
        'Error: Yarn executable was not detected in the system.'.color(:red),
        'Download Yarn at https://yarnpkg.com/en/docs/install'.color(:green)
      )
      abort
    end
  end

  desc 'Ensure Node dependencies are installed'
  task check: ['yarn:available'] do
    unless system('yarn check --ignore-engines', out: File::NULL)
      warn(
        'Error: You have unmet dependencies. (`yarn check` command failed)'.color(:red),
        'Run `yarn install` to install missing modules.'.color(:green)
      )
      abort
    end
  end

  desc 'Install Node dependencies with Yarn'
  task install: ['yarn:available'] do
    unless system('yarn install --pure-lockfile --ignore-engines --prefer-offline')
      abort 'Error: Unable to install node modules.'.color(:red)
    end
  end

  desc 'Remove Node dependencies'
  task :clobber do
    warn 'Purging ./node_modules directory'.color(:red)
    FileUtils.rm_rf 'node_modules'
  end
end

desc 'Install Node dependencies with Yarn'
task yarn: ['yarn:install']
