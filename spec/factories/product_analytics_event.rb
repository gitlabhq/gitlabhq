# frozen_string_literal: true

FactoryBot.define do
  factory :product_analytics_event do
    project
    platform { 'web' }
    collector_tstamp { DateTime.now }
    dvce_created_tstamp { DateTime.now }
    event_id { SecureRandom.uuid }
    name_tracker { 'sp' }
    v_tracker { 'js-2.14.0' }
    v_collector { 'GitLab 13.1.0-pre' }
    v_etl { 'GitLab 13.1.0-pre' }
    domain_userid { SecureRandom.uuid }
    domain_sessionidx { 4 }
    page_url { 'http://localhost:3333/products/123' }
    br_lang { 'en-US' }
    br_cookies { true }
    br_colordepth { '24' }
    os_timezone { 'America/Los_Angeles' }
    doc_charset { 'UTF-8' }
    domain_sessionid { SecureRandom.uuid }
  end
end
