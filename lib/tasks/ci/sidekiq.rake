namespace :ci do
  namespace :sidekiq do
    desc "GitLab CI | Stop sidekiq"
    task :stop do
      exec({'RAILS_ENV' => Rails.env}, 'script/background_jobs stop')
    end

    desc "GitLab CI | Start sidekiq"
    task :start do
      exec({'RAILS_ENV' => Rails.env}, 'script/background_jobs start')
    end
  end
end
