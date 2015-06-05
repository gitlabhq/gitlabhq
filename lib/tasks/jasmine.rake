# Since we no longer explicitly require the 'jasmine' gem, we lost the
# `jasmine:ci` task used by GitLab CI jobs.
#
# This provides a simple alias to run the `spec:javascript` task from the
# 'jasmine-rails' gem.
task jasmine: ['jasmine:ci']

namespace :jasmine do
  task :ci do
    Rake::Task['teaspoon'].invoke
  end
end
