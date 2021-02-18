# frozen_string_literal: true

module ConfigLint
  def self.run(files)
    failures = files.reject do |file|
      yield(file)
    end

    if failures.present?
      puts failures
      exit failures.count
    end
  end
end

desc "Checks syntax for shell scripts and nginx config files in 'lib/support/'"
task :config_lint do
  shell_scripts = [
    'lib/support/init.d/gitlab',
    'lib/support/init.d/gitlab.default.example',
    'lib/support/deploy/deploy.sh'
  ]

  ConfigLint.run(shell_scripts) do |file|
    Kernel.system('bash', '-n', file)
  end
end
