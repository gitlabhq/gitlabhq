namespace :gitlab do
  namespace :app do
    desc "GITLAB | Setup production application"
    task :setup => [
      'db:setup',
      'db:seed_fu',
      'gitlab:enable_automerge'
    ]
  end
end
