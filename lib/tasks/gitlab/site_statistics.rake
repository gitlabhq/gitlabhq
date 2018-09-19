namespace :gitlab do
  desc "GitLab | Refresh Site Statistics counters"
  task refresh_site_statistics: :environment do
    puts 'Updating Site Statistics counters: '

    print '* Repositories... '
    SiteStatistic.transaction do
      # see https://gitlab.com/gitlab-org/gitlab-ce/issues/48967
      ActiveRecord::Base.connection.execute('SET LOCAL statement_timeout TO 0') if Gitlab::Database.postgresql?
      SiteStatistic.update_all('repositories_count = (SELECT COUNT(*) FROM projects)')
    end
    puts 'OK!'.color(:green)

    print '* Wikis... '
    SiteStatistic.transaction do
      # see https://gitlab.com/gitlab-org/gitlab-ce/issues/48967
      ActiveRecord::Base.connection.execute('SET LOCAL statement_timeout TO 0') if Gitlab::Database.postgresql?
      SiteStatistic.update_all('wikis_count = (SELECT COUNT(*) FROM project_features WHERE wiki_access_level != 0)')
    end
    puts 'OK!'.color(:green)
    puts
  end
end
