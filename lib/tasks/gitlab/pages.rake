namespace :gitlab do
  namespace :pages do
    desc 'Ping the pages admin API'
    task admin_ping: :gitlab_environment do
      Gitlab::PagesClient.ping
      puts "OK: gitlab-pages admin API is reachable"
    end
  end
end
