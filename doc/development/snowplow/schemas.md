---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Snowplow schemas

This page provides Snowplow schema reference for GitLab events.

## `gitlab_standard`

We are including the [`gitlab_standard` schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_standard/jsonschema/) for structured events and page views.

The [`StandardContext`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/tracking/standard_context.rb)
class represents this schema in the application. Some properties are
[automatically populated for frontend events](implementation.md#snowplow-javascript-frontend-tracking),
and can be [provided manually for backend events](implementation.md#implement-ruby-backend-tracking).

| Field Name     | Required            | Default value | Type                  | Description                                                                                 |
|----------------|:-------------------:|-----------------------|--|---------------------------------------------------------------------------------------------|
| `project_id`   | **{dotted-circle}** | Current project ID * | integer               |                                                                 |
| `namespace_id` | **{dotted-circle}** | Current group/namespace ID * | integer               |                                                               |
| `user_id`      | **{dotted-circle}** | Current user ID * | integer               | User database record ID attribute. This value undergoes a pseudonymization process at the collector level. |
| `context_generated_at` | **{dotted-circle}** | Current timestamp | string (date time format) | Timestamp indicating when context was generated.                                                                |
| `environment`  | **{check-circle}**  | Current environment | string (max 32 chars) | Name of the source environment, such as `production` or `staging`             |
| `source`       | **{check-circle}**  | Event source | string (max 32 chars) | Name of the source application, such as  `gitlab-rails` or `gitlab-javascript` |
| `plan`         | **{dotted-circle}**  | Current namespace plan * | string (max 32 chars) | Name of the plan for the namespace, such as `free`, `premium`, or `ultimate`. Automatically picked from the `namespace`. |
| `google_analytics_id` | **{dotted-circle}**  | GA ID value * | string (max 32 chars) | Google Analytics ID, present when set from our marketing sites. |
| `extra`        | **{dotted-circle}**  |  | JSON                  | Any additional data associated with the event, in the form of key-value pairs |

_\* Default value present for frontend events only_

## Default Schema

Frontend events include a [web-specific schema](https://docs.snowplow.io/docs/understanding-your-pipeline/canonical-event/#web-specific-fields) provided by Snowplow.
All URLs are pseudonymized. The entity identifier [replaces](https://docs.snowplow.io/docs/collecting-data/collecting-from-own-applications/javascript-trackers/javascript-tracker/javascript-tracker-v2/tracker-setup/other-parameters-2/#setting-a-custom-page-url-and-referrer-url) personally identifiable
information (PII). PII includes usernames, group, and project names.
Page titles are hardcoded as `GitLab` for the same reason.

| Field Name               | Required            | Type      | Description                                                                                                                      |
|--------------------------|---------------------|-----------|----------------------------------------------------------------------------------------------------------------------------------|
| `app_id`                   | **{check-circle}**  | string    | Unique identifier for website / application                                                                                      |
| `base_currency`            | **{dotted-circle}** | string    | Reporting currency                                                                                                               |
| `br_colordepth`            | **{dotted-circle}** | integer   | Browser color depth                                                                                                              |
| `br_cookies`               | **{dotted-circle}** | boolean   | Does the browser permit cookies?                                                                                                 |
| `br_family`                | **{dotted-circle}** | string    | Browser family                                                                                                                   |
| `br_features_director`     | **{dotted-circle}** | boolean   | Director plugin installed?                                                                                                       |
| `br_features_flash`        | **{dotted-circle}** | boolean   | Flash plugin installed?                                                                                                          |
| `br_features_gears`        | **{dotted-circle}** | boolean   | Google gears installed?                                                                                                          |
| `br_features_java`         | **{dotted-circle}** | boolean   | Java plugin installed?                                                                                                           |
| `br_features_pdf`          | **{dotted-circle}** | boolean   | Adobe PDF plugin installed?                                                                                                      |
| `br_features_quicktime`    | **{dotted-circle}** | boolean   | Quicktime plugin installed?                                                                                                      |
| `br_features_realplayer`   | **{dotted-circle}** | boolean   | RealPlayer plugin installed?                                                                                                     |
| `br_features_silverlight`  | **{dotted-circle}** | boolean   | Silverlight plugin installed?                                                                                                    |
| `br_features_windowsmedia` | **{dotted-circle}** | boolean   | Windows media plugin installed?                                                                                                  |
| `br_lang`                  | **{dotted-circle}** | string    | Language the browser is set to                                                                                                   |
| `br_name`                  | **{dotted-circle}** | string    | Browser name                                                                                                                     |
| `br_renderengine`          | **{dotted-circle}** | string    | Browser rendering engine                                                                                                         |
| `br_type`                  | **{dotted-circle}** | string    | Browser type                                                                                                                     |
| `br_version`               | **{dotted-circle}** | string    | Browser version                                                                                                                  |
| `br_viewheight`            | **{dotted-circle}** | string    | Browser viewport height                                                                                                          |
| `br_viewwidth`             | **{dotted-circle}** | string    | Browser viewport width                                                                                                           |
| `collector_tstamp`         | **{dotted-circle}** | timestamp | Time stamp for the event recorded by the collector                                                                               |
| `contexts`                 | **{dotted-circle}** |           |                                                                                                                                  |
| `derived_contexts`         | **{dotted-circle}** |           | Contexts derived in the Enrich process                                                                                           |
| `derived_tstamp`           | **{dotted-circle}** | timestamp | Timestamp making allowance for inaccurate device clock                                                                          |
| `doc_charset`              | **{dotted-circle}** | string    | Web page's character encoding                                                                                                    |
| `doc_height`               | **{dotted-circle}** | string    | Web page height                                                                                                                  |
| `doc_width`                | **{dotted-circle}** | string    | Web page width                                                                                                                   |
| `domain_sessionid`         | **{dotted-circle}** | string    | Unique identifier (UUID) for this visit of this `user_id` to this domain                                                         |
| `domain_sessionidx`        | **{dotted-circle}** | integer   | Index of number of visits that this `user_id` has made to this domain (The first visit is `1`)                                   |
| `domain_userid`            | **{dotted-circle}** | string    | Unique identifier for a user, based on a first party cookie (so domain specific)                                                 |
| `dvce_created_tstamp`      | **{dotted-circle}** | timestamp | Timestamp when event occurred, as recorded by client device                                                                      |
| `dvce_ismobile`            | **{dotted-circle}** | boolean   | Indicates whether device is mobile                                                                                               |
| `dvce_screenheight`        | **{dotted-circle}** | string    | Screen / monitor resolution                                                                                                      |
| `dvce_screenwidth`         | **{dotted-circle}** | string    | Screen / monitor resolution                                                                                                      |
| `dvce_sent_tstamp`         | **{dotted-circle}** | timestamp | Timestamp when event was sent by client device to collector                                                                      |
| `dvce_type`                | **{dotted-circle}** | string    | Type of device                                                                                                                   |
| `etl_tags`                 | **{dotted-circle}** | string    | JSON of tags for this ETL run                                                                                                    |
| `etl_tstamp`               | **{dotted-circle}** | timestamp | Timestamp event began ETL                                                                                                        |
| `event`                    | **{dotted-circle}** | string    | Event type                                                                                                                       |
| `event_fingerprint`        | **{dotted-circle}** | string    | Hash client-set event fields                                                                                                     |
| `event_format`             | **{dotted-circle}** | string    | Format for event                                                                                                                 |
| `event_id`                 | **{dotted-circle}** | string    | Event UUID                                                                                                                       |
| `event_name`               | **{dotted-circle}** | string    | Event name                                                                                                                       |
| `event_vendor`             | **{dotted-circle}** | string    | The company who developed the event model                                                                                        |
| `event_version`            | **{dotted-circle}** | string    | Version of event schema                                                                                                          |
| `geo_city`                 | **{dotted-circle}** | string    | City of IP origin                                                                                                                |
| `geo_country`              | **{dotted-circle}** | string    | Country of IP origin                                                                                                             |
| `geo_latitude`             | **{dotted-circle}** | string    | An approximate latitude                                                                                                          |
| `geo_longitude`            | **{dotted-circle}** | string    | An approximate longitude                                                                                                         |
| `geo_region`               | **{dotted-circle}** | string    | Region of IP origin                                                                                                              |
| `geo_region_name`          | **{dotted-circle}** | string    | Region of IP origin                                                                                                              |
| `geo_timezone`             | **{dotted-circle}** | string    | Time zone of IP origin                                                                                                            |
| `geo_zipcode`              | **{dotted-circle}** | string    | Zip (postal) code of IP origin                                                                                                   |
| `ip_domain`                | **{dotted-circle}** | string    | Second level domain name associated with the visitor's IP address                                                                |
| `ip_isp`                   | **{dotted-circle}** | string    | Visitor's ISP                                                                                                                    |
| `ip_netspeed`              | **{dotted-circle}** | string    | Visitor's connection type                                                                                                        |
| `ip_organization`          | **{dotted-circle}** | string    | Organization associated with the visitor's IP address – defaults to ISP name if none is found                                    |
| `mkt_campaign`             | **{dotted-circle}** | string    | The campaign ID                                                                                                                  |
| `mkt_clickid`              | **{dotted-circle}** | string    | The click ID                                                                                                                     |
| `mkt_content`              | **{dotted-circle}** | string    | The content or ID of the ad.                                                                   |
| `mkt_medium`               | **{dotted-circle}** | string    | Type of traffic source                                                                                                           |
| `mkt_network`              | **{dotted-circle}** | string    | The ad network to which the click ID belongs                                                                                     |
| `mkt_source`               | **{dotted-circle}** | string    | The company / website where the traffic came from                                                                                |
| `mkt_term`                 | **{dotted-circle}** | string    | Keywords associated with the referrer                                                                                        |
| `name_tracker`             | **{dotted-circle}** | string    | The tracker namespace                                                                                                            |
| `network_userid`           | **{dotted-circle}** | string    | Unique identifier for a user, based on a cookie from the collector (so set at a network level and shouldn't be set by a tracker) |
| `os_family`                | **{dotted-circle}** | string    | Operating system family                                                                                                          |
| `os_manufacturer`          | **{dotted-circle}** | string    | Manufacturers of operating system                                                                                                |
| `os_name`                  | **{dotted-circle}** | string    | Name of operating system                                                                                                         |
| `os_timezone`              | **{dotted-circle}** | string    | Client operating system time zone                                                                                                 |
| `page_referrer`            | **{dotted-circle}** | string    | Referrer URL                                                                                                                     |
| `page_title`               | **{dotted-circle}** | string    | To not expose personal identifying information, the page title is hardcoded as `GitLab`                                          |
| `page_url`                 | **{dotted-circle}** | string    | Page URL                                                                                                                         |
| `page_urlfragment`         | **{dotted-circle}** | string    | Fragment aka anchor                                                                                                              |
| `page_urlhost`             | **{dotted-circle}** | string    | Host aka domain                                                                                                                  |
| `page_urlpath`             | **{dotted-circle}** | string    | Path to page                                                                                                                     |
| `page_urlport`             | **{dotted-circle}** | integer   | Port if specified, 80 if not                                                                                                     |
| `page_urlquery`            | **{dotted-circle}** | string    | Query string                                                                                                                      |
| `page_urlscheme`           | **{dotted-circle}** | string    | Scheme (protocol name)                                                                                                              |
| `platform`                 | **{dotted-circle}** | string    | The platform the app runs on                                                                                                     |
| `pp_xoffset_max`           | **{dotted-circle}** | integer   | Maximum page x offset seen in the last ping period                                                                               |
| `pp_xoffset_min`           | **{dotted-circle}** | integer   | Minimum page x offset seen in the last ping period                                                                               |
| `pp_yoffset_max`           | **{dotted-circle}** | integer   | Maximum page y offset seen in the last ping period                                                                               |
| `pp_yoffset_min`           | **{dotted-circle}** | integer   | Minimum page y offset seen in the last ping period                                                                               |
| `refr_domain_userid`       | **{dotted-circle}** | string    | The Snowplow `domain_userid` of the referring website                                                                              |
| `refr_dvce_tstamp`         | **{dotted-circle}** | timestamp | The time of attaching the `domain_userid` to the inbound link                                                                      |
| `refr_medium`              | **{dotted-circle}** | string    | Type of referer                                                                                                                  |
| `refr_source`              | **{dotted-circle}** | string    | Name of referer if recognised                                                                                                    |
| `refr_term`                | **{dotted-circle}** | string    | Keywords if source is a search engine                                                                                            |
| `refr_urlfragment`         | **{dotted-circle}** | string    | Referer URL fragment                                                                                                             |
| `refr_urlhost`             | **{dotted-circle}** | string    | Referer host                                                                                                                     |
| `refr_urlpath`             | **{dotted-circle}** | string    | Referer page path                                                                                                                |
| `refr_urlport`             | **{dotted-circle}** | integer   | Referer port                                                                                                                     |
| `refr_urlquery`            | **{dotted-circle}** | string    | Referer URL query string                                                                                                          |
| `refr_urlscheme`           | **{dotted-circle}** | string    | Referer scheme                                                                                                                   |
| `se_action`                | **{dotted-circle}** | string    | The action / event itself                                                                                                        |
| `se_category`              | **{dotted-circle}** | string    | The category of event                                                                                                            |
| `se_label`                 | **{dotted-circle}** | string    | A label often used to refer to the 'object' the action is performed on                                                           |
| `se_property`              | **{dotted-circle}** | string    | A property associated with either the action or the object                                                                       |
| `se_value`                 | **{dotted-circle}** | decimal   | A value associated with the user action                                                                                          |
| `ti_category`              | **{dotted-circle}** | string    | Item category                                                                                                                    |
| `ti_currency`              | **{dotted-circle}** | string    | Currency                                                                                                                         |
| `ti_name`                  | **{dotted-circle}** | string    | Item name                                                                                                                        |
| `ti_orderid`               | **{dotted-circle}** | string    | Order ID                                                                                                                         |
| `ti_price`                 | **{dotted-circle}** | decimal   | Item price                                                                                                                       |
| `ti_price_base`            | **{dotted-circle}** | decimal   | Item price in base currency                                                                                                      |
| `ti_quantity`              | **{dotted-circle}** | integer   | Item quantity                                                                                                                    |
| `ti_sku`                   | **{dotted-circle}** | string    | Item SKU                                                                                                                         |
| `tr_affiliation`           | **{dotted-circle}** | string    | Transaction affiliation (such as channel)                                                                                           |
| `tr_city`                  | **{dotted-circle}** | string    | Delivery address: city                                                                                                           |
| `tr_country`               | **{dotted-circle}** | string    | Delivery address: country                                                                                                        |
| `tr_currency`              | **{dotted-circle}** | string    | Transaction Currency                                                                                                             |
| `tr_orderid`               | **{dotted-circle}** | string    | Order ID                                                                                                                         |
| `tr_shipping`              | **{dotted-circle}** | decimal   | Delivery cost charged                                                                                                            |
| `tr_shipping_base`         | **{dotted-circle}** | decimal   | Shipping cost in base currency                                                                                                   |
| `tr_state`                 | **{dotted-circle}** | string    | Delivery address: state                                                                                                          |
| `tr_tax`                   | **{dotted-circle}** | decimal   | Transaction tax value (such as amount of VAT included)                                                                              |
| `tr_tax_base`              | **{dotted-circle}** | decimal   | Tax applied in base currency                                                                                                     |
| `tr_total`                 | **{dotted-circle}** | decimal   | Transaction total value                                                                                                          |
| `tr_total_base`            | **{dotted-circle}** | decimal   | Total amount of transaction in base currency                                                                                     |
| `true_tstamp`              | **{dotted-circle}** | timestamp | User-set exact timestamp                                                                                                         |
| `txn_id`                   | **{dotted-circle}** | string    | Transaction ID                                                                                                                   |
| `unstruct_event`           | **{dotted-circle}** | JSON      | The properties of the event                                                                                                      |
| `uploaded_at`              | **{dotted-circle}** |           |                                                                                                                                  |
| `user_fingerprint`         | **{dotted-circle}** | integer   | User identifier based on (hopefully unique) browser features                                                                     |
| `user_id`                  | **{dotted-circle}** | string    | Unique identifier for user, set by the business using setUserId                                                                  |
| `user_ipaddress`           | **{dotted-circle}** | string    | IP address                                                                                                                       |
| `useragent`                | **{dotted-circle}** | string    | User agent (expressed as a browser string)                                                                                                |
| `v_collector`              | **{dotted-circle}** | string    | Collector version                                                                                                                |
| `v_etl`                    | **{dotted-circle}** | string    | ETL version                                                                                                                      |
| `v_tracker`                | **{dotted-circle}** | string    | Identifier for Snowplow tracker                                                                                                  |

## `gitlab_service_ping`

Backend events converted from ServicePing (`redis` and `redis_hll`) must include [ServicePing context](https://gitlab.com/gitlab-org/iglu/-/tree/master/public/schemas/com.gitlab/gitlab_service_ping/jsonschema)
using the [helper class](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/tracking/service_ping_context.rb).

An example of converted `redis_hll` [event with context](https://gitlab.com/gitlab-org/gitlab/-/edit/master/app/controllers/concerns/product_analytics_tracking.rb#L58).

| Field Name    |      Required       | Type                   | Description                                                                                                                                                        |
|---------------|:-------------------:|------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `data_source` | **{check-circle}**  | string (max 64 chars)  | The `data_source` attribute from the metrics YAML definition. |
| `event_name`* | **{dotted-circle}** | string (max 128 chars) | When there is a many-to-many relationship between events and metrics, this field contains the name of a Redis event that can be used for aggregations in downstream systems |
| `key_path`*   | **{dotted-circle}** | string (max 256 chars) | The `key_path` attribute from the metrics YAML definition |

_\* Either `event_name` or `key_path` is required_
