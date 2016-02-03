namespace :ci do
  namespace :slack do
    desc "GitLab CI | Send slack notification on build failure"
    task :error, [:channel, :error] do |t, args|
      next unless !"#{ENV['CI_SLACK_WEBHOOK_URL']}".blank? && args.channel && args.error
      Kernel.system "curl -X POST --data-urlencode 'payload={\"channel\": \"#{args.channel}\", \"username\": \"gitlab-ci\", \"text\": \"#{args.error}\", \"icon_emoji\": \":gitlab:\"}' $CI_SLACK_WEBHOOK_URL"
    end
  end
end
