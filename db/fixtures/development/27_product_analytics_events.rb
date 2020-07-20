# frozen_string_literal: true

Gitlab::Seeder.quiet do
  # The data set takes approximately 2 minutes to load,
  # so its put behind the flag. To seed this data use the flag and the filter:
  # SEED_PRODUCT_ANALYTICS_EVENTS=1 FILTER=product_analytics_events rake db:seed_fu
  flag = 'SEED_PRODUCT_ANALYTICS_EVENTS'

  if ENV[flag]
    Project.all.sample(2).each do |project|
      # Let's generate approx a week of events from now into the past with 1 minute step.
      # To add some differentiation we add a random offset of up to 45 seconds.
      10000.times do |i|
        dvce_created_tstamp = DateTime.now - i.minute - rand(45).seconds

        # Add a random delay to collector timestamp. Up to 2 seconds.
        collector_tstamp = dvce_created_tstamp + rand(3).second

        ProductAnalyticsEvent.create!(
          project_id: project.id,
          platform: ["web", "mob", "mob", "app"].sample,
          collector_tstamp: collector_tstamp,
          dvce_created_tstamp: dvce_created_tstamp,
          event: nil,
          event_id: SecureRandom.uuid,
          name_tracker: "sp",
          v_tracker: "js-2.14.0",
          v_collector: Gitlab::VERSION,
          v_etl: Gitlab::VERSION,
          domain_userid: SecureRandom.uuid,
          domain_sessionidx: 4,
          page_url: "#{project.web_url}/-/product_analytics/test",
          page_title: 'Test page',
          page_referrer: "#{project.web_url}/-/product_analytics/test",
          br_lang: ["en-US", "en-US", "en-GB", "nl", "fi"].sample, # https://www.andiamo.co.uk/resources/iso-language-codes/
          br_features_pdf: true,
          br_cookies: [true, true, true, false].sample,
          br_colordepth: ["24", "24", "16", "8"].sample,
          os_timezone: ["America/Los_Angeles", "America/Los_Angeles", "America/Lima", "Asia/Dubai", "Africa/Bangui"].sample, # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
          doc_charset: ["UTF-8", "UTF-8", "UTF-8", "DOS", "EUC"].sample,
          domain_sessionid: SecureRandom.uuid
        )
      end

      unless Feature.enabled?(:product_analytics, project)
        if Feature.enable(:product_analytics, project)
          puts "Product analytics feature was enabled for #{project.full_path}"
        end
      end

      puts "10K events added to #{project.full_path}"
    end
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
