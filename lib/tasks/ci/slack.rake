namespace :ci do
  namespace :slack do
    desc "GitLab CI | Send slack notification on build failure"
    task error: :environment do
      error_text = 'Build failed for master/tags'
      Kernel.system "curl -X POST --data-urlencode 'payload={\"channel\": \"#ci-test\", \"username\": \"gitlab-ci\", \"text\": \"#{error_text}\", \"icon_emoji\": \":gitlab:\"}' $CI_SLACK_WEBHOOK_URL"
    end
  end
end
