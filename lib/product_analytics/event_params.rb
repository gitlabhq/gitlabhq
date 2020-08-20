# frozen_string_literal: true

module ProductAnalytics
  # Converts params from Snowplow tracker to one compatible with
  # GitLab ProductAnalyticsEvent model. The field naming corresponds
  # with snowplow event model. Only project_id is GitLab specific.
  #
  # For information on what each field is you can check next resources:
  # * Snowplow tracker protocol: https://github.com/snowplow/snowplow/wiki/snowplow-tracker-protocol
  # * Canonical event model: https://github.com/snowplow/snowplow/wiki/canonical-event-model
  class EventParams
    def self.parse_event_params(params)
      {
        project_id:               params['aid'],
        platform:                 params['p'],
        collector_tstamp:         Time.zone.now,
        event_id:                 params['eid'],
        v_tracker:                params['tv'],
        v_collector:              Gitlab::VERSION,
        v_etl:                    Gitlab::VERSION,
        os_timezone:              params['tz'],
        name_tracker:             params['tna'],
        br_lang:                  params['lang'],
        doc_charset:              params['cs'],
        br_features_pdf:          Gitlab::Utils.to_boolean(params['f_pdf']),
        br_features_flash:        Gitlab::Utils.to_boolean(params['f_fla']),
        br_features_java:         Gitlab::Utils.to_boolean(params['f_java']),
        br_features_director:     Gitlab::Utils.to_boolean(params['f_dir']),
        br_features_quicktime:    Gitlab::Utils.to_boolean(params['f_qt']),
        br_features_realplayer:   Gitlab::Utils.to_boolean(params['f_realp']),
        br_features_windowsmedia: Gitlab::Utils.to_boolean(params['f_wma']),
        br_features_gears:        Gitlab::Utils.to_boolean(params['f_gears']),
        br_features_silverlight:  Gitlab::Utils.to_boolean(params['f_ag']),
        br_colordepth:            params['cd'],
        br_cookies:               Gitlab::Utils.to_boolean(params['cookie']),
        dvce_created_tstamp:      params['dtm'],
        br_viewheight:            params['vp'],
        domain_sessionidx:        params['vid'],
        domain_sessionid:         params['sid'],
        domain_userid:            params['duid'],
        user_fingerprint:         params['fp'],
        page_referrer:            params['refr'],
        page_url:                 params['url'],
        se_category:              params['se_ca'],
        se_action:                params['se_ac'],
        se_label:                 params['se_la'],
        se_property:              params['se_pr'],
        se_value:                 params['se_va']
      }
    end

    def self.has_required_params?(params)
      params['aid'].present? && params['eid'].present?
    end
  end
end
