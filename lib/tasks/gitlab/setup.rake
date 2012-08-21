namespace :gitlab do
  namespace :app do
    desc "GITLAB | Setup production application"
    task :setup => [
      'db:setup',
      'db:seed_fu',
      'gitlab:gitolite:write_hooks',
      'gitlab:app:enable_automerge' 
    ]
  end
end

