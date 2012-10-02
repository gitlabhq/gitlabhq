namespace :gitlab do
  namespace :app do
    desc "GITLAB | Setup production application"
    task :setup => [
      'db:setup',
      'gitlab:app:enable_automerge'
    ]
  end
end
