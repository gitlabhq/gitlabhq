namespace :gitlab do
  namespace :usage_data do
    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in YAML'
    task dump_sql_in_yaml: :environment do
      puts Gitlab::UsageDataQueries.uncached_data.to_yaml
    end

    desc 'GitLab | UsageData | Generate raw SQLs for usage ping in JSON'
    task dump_sql_in_json: :environment do
      puts Gitlab::Json.pretty_generate(Gitlab::UsageDataQueries.uncached_data)
    end
  end
end
