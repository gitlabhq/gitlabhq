---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Internal Events Payload Samples
---

## Internal Events Payload

This guide provides payload samples for internal events tracked across frontend and backend services. Each event type includes a detailed breakdown of its fields and descriptions. Internal events use Snowplow to track events. For more information, see [Snowplow event parameters guide](https://docs.snowplow.io/docs/sources/trackers/snowplow-tracker-protocol/going-deeper/event-parameters/).

From GitLab 18.0, Self-Managed and Dedicated instances will be sending structured events, self-describing events, page views, and page pings.

## Event Types

At its core, our Internal Events tracking system is designed for granular tracking of events. Each event is denoted by an `e=...` parameter.

There are three categories of events:

- Standard events, such as page views and page pings
- Custom structured events
- Self-describing events based on a schema

| **Type of tracking**                | **Event type (value of e)** |
| ----------------------------------- | --------------------------- |
| Self-describing event               | ue                          |
| Pageview tracking                   | pv                          |
| Page pings                          | pp                          |
| Custom structured event             | se                          |

## Common Parameters

### Event Parameters

| **Parameter** | **Table Column** | **Type** | **Description** | **Example values** |
| ------------- | ---------------- | -------- | --------------- | ------------------ |
| e             | event            | text     | Event type      | pv, pp, ue, se     |
| eid           | `event_id`         | text     | Event UUID      | 606adff6-9ccc-41f4-8807-db8fdb600df8 |

### Application Parameters

| **Parameter** | **Table Column** | **Type** | **Description** | **Example values** |
| ------------- | ---------------- | -------- | --------------- | ------------------ |
| tna           | namespace_tracker     | text     | The tracker namespace | `gl` |
| aid           | `app_id`           | text     | Unique identifier for the application | `gitlab-sm`|
| p             | platform         | text     | The platform the app runs on | web, srv, app |
| tv            | v_tracker        | text     | Identifier for tracker version | js-3.24.2 |

### Timestamp Parameters

| **Parameter** | **Table Column**      | **Type** | **Description** | **Example values** |
| ------------- | --------------------- | -------- | --------------- | ------------------ |
| dtm           | dvce_created_tstamp   | int      | Timestamp when event occurred, as recorded by client device | 1361553733313 |
| stm           | dvce_sent_tstamp      | int      | Timestamp when event was sent by client device to collector | 1361553733371 |
| ttm           | true_tstamp           | int      | User-set exact timestamp | 1361553733371 |
| tz            | os_timezone           | text     | Time zone of client devices OS | Europe%2FLondon |

> **Note:** The Internal Events Collector will also capture `collector_tstamp` which is the time the event arrived at the collector.

### User-Related Parameters

| **Parameter** | **Table Column**   | **Type** | **Description** | **Example values** |
| ------------- | ------------------ | -------- | --------------- | ------------------ |
| duid          | `domain_userid`      | text     | Unique rotating identifier for a user, based on a first-party cookie. | aeb1691c5a0ee5a6 |
| uid           | `user_id`            | text     | `user_id`, which gets pseudonymized in the snowplow [pipeline](https://metrics.gitlab.com/identifiers/) | 1234567890 |
| vid           | `domain_sessionidx`  | int      | Index of number of visits that this user has made to the application | 1 |
| sid           | `domain_sessionid`   | text     | Unique identifier (UUID) generated to track a user's activity during a single visit or session. This identifier resets between sessions. The identifier is not linked to personal information.   | 9c65e7f3-8e8e-470d-b243-910b5b300da0 |
| `ip`            | `user_ipaddress`, we collect Geo information but do not store the IP address in the snowplow pipeline   | text     | IP address override | 37.157.33.178 |

### Platform Parameters

| **Parameter** | **Table Column** | **Type** | **Description** | **Example values** |
| ------------- | ---------------- | -------- | --------------- | ------------------ |
| `url`           | `page_url`         | text     | Page URL. We pseudonymize sensitive data from the URL ([see examples](https://metrics.gitlab.com/identifiers/)).        | `https://gitlab.com/dashboard/projects` |
| `ua`            | `useragent`        | text     | Useragent       | `Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:105.0) Gecko/20100101 Firefox/105.0` |
| `page`          | page_title       | text     | This value will always be hardcoded to `GitLab`      | GitLab |
| refr          | page_referrer    | text     | Referrer URL, similar to `page_url`. We pseudonymize referrer URL.  | `https://gitlab.com/group:123/project:356` |
| cookie        | br_cookies       | boolean  | Does the browser permit cookies? | 1 |
| lang          | br_lang          | text     | Browser language | en-US |
| cd            | br_colordepth    | integer  | Browser color depth | 24 |
| cs            | doc_charset      | text     | Web page's character encoding | UTF-8 |
| ds            | doc_width and doc_height | text | Web page width and height | 1090x1152 |
| vp            | br_viewwidth and br_viewheight | text | Browser viewport width and height | 1105x390 |
| res           | dvce_screenwidth and dvce_screenheight | text | Screen/monitor resolution | 1280x1024 |

## Self-describing Events

Self-describing events are the recommended way to track custom events with Internal Events tracking. They allow tracking of events according to a predefined schema.

When tracking a self-describing event:

- The event type is set to `e=ue`.
- The event data is base64 encoded and included in the payload.

## Specific Event Types

### Page Views

Pageview tracking is used to record views of web pages.

Recording a pageview involves recording an event where `e=pv`. All the fields associated with web events can be tracked.

### Page Pings

Page ping events track user engagement by periodically firing while a user remains active on a page. They measure actual time spent on page.

Page pings are identified by `e=pp` and include these additional fields:

| **Parameter** | **Table Column** | **Type** | **Description** |
| ------------- | ---------------- | -------- | --------------- |
| pp_mix        | pp_xoffset_min   | integer  | Minimum page x offset seen in the last ping period |
| pp_max        | pp_xoffset_max   | integer  | Maximum page x offset seen in the last ping period |
| pp_miy        | pp_yoffset_min   | integer  | Minimum page y offset seen in the last ping period |
| pp_may        | pp_yoffset_max   | integer  | Maximum page y offset seen in the last ping period |

### Structured Event Tracking

As well as setting `e=se`, there are five custom event specific parameters that can be set:

| **Parameter** | **Table Column** | **Type** | **Description** | **Example values** |
| ------------- | ---------------- | -------- | --------------- | ------------------ |
| se_ca         | se_category      | text     | The event category. By default, where the event happened. For frontend events, it is the page name, for backend events it is the controller name. | projects:merge_requests:show |
| se_ac         | se_action        | text     | The action or event name | code_suggestion_accepted |
| se_la         | se_label         | text     | A label often used to refer to the 'object' the action is performed on | `${editor_name}` |
| se_pr         | se_property      | text     | A property associated with either the action or the object | `${suggestion_type}` |
| se_va         | se_value         | decimal  | A value associated with the user action | `${suggestion_shown_duration}` |
| cx         | contexts         | JSON  | It passes base64 encoded context to the event |  JSON |

Contexts has some of the predefined fields which will be sent with each event. All the predefined schemas are stored in the [`gitlab-org/iglu`](https://gitlab.com/gitlab-org/iglu) repository.

Most of the self-describing events have `gitlab_standard` context, which is a set of fields that are common to all events. For more information about the `gitlab_standard` context, see [Standard context fields](standard_context_fields.md).

## Internal Events Payload Examples

### Page View

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4",
  "data": [
    {
      "e": "pv",
      "url": "https://gitlab.com/",
      "page": "GitLab",
      "refr": "https://gitlab.com/",
      "eid": "564f9834-3f98-4d78-a738-b7977d621371",
      "tv": "js-3.24.2",
      "tna": "gl",
      "aid": "gitlab",
      "p": "web",
      "cookie": "1",
      "cs": "UTF-8",
      "lang": "en-GB",
      "res": "1728x1117",
      "cd": "30",
      "tz": "Asia/Calcutta",
      "dtm": "1742205227525",
      "vp": "1920x331",
      "ds": "1920x388",
      "vid": "720",
      "sid": "1574509e-5d6d-43d1-9e76-e42801ae2e55",
      "duid": "9e5500ac-3437-4457-a007-351911d54983",
      "cx": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy5z...",
      "stm": "1742205227528"
    }
  ]
}
```

cx field is base64 encoded and contains the following JSON:

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-0",
  "data": [
    {
      "schema": "iglu:com.gitlab/gitlab_standard/jsonschema/1-1-1",
      "data": {
        "environment": "production",
        "source": "gitlab-javascript",
        "correlation_id": "01JPHRC3K30KDDV165EWTCFJ02",
        "plan": null,
        "extra": {},
        "user_id": 11979729,
        "global_user_id": "XsZfAb677xjp9zut/lL6X0ZKX5b7pli65uk2wnfu0SY=",
        "is_gitlab_team_member": true,
        "namespace_id": null,
        "project_id": null,
        "feature_enabled_by_namespace_ids": null,
        "realm": "saas",
        "instance_id": "ea8bf810-1d6f-4a6a-b4fd-93e8cbd8b57f",
        "host_name": "gitlab-webservice-web-58446c98b5-zprvd",
        "instance_version": "17.10.0",
        "context_generated_at": "2025-03-17T09:53:46.709Z",
        "google_analytics_id": "GA1.1.424273043.1737451027"
      }
    },
    {
      "schema": "iglu:com.snowplowanalytics.snowplow/web_page/jsonschema/1-0-0",
      "data": {
        "id": "90ea98bd-3bdb-48d2-935c-59a4d03a4710"
      }
    },
    {
      "schema": "iglu:com.google.analytics/cookies/jsonschema/1-0-0",
      "data": {
        "_ga": "GA1.1.424273043.1737451027"
      }
    },
    {
      "schema": "iglu:com.google.ga4/cookies/jsonschema/1-0-0",
      "data": {
        "_ga": "GA1.1.424273043.1737451027",
        "session_cookies": [
          {
            "measurement_id": "G-ENFH3X7M5Y",
            "session_cookie": "GS1.1.1742200876.45.1.1742202521.0.0.0"
          }
        ]
      }
    },
    {
      "schema": "iglu:org.w3/PerformanceTiming/jsonschema/1-0-0",
      "data": {
        "navigationStart": 1742205226288,
        "redirectStart": 0,
        "redirectEnd": 0,
        "fetchStart": 1742205226289,
        "domainLookupStart": 1742205226289,
        "domainLookupEnd": 1742205226289,
        "connectStart": 1742205226289,
        "secureConnectionStart": 0,
        "connectEnd": 1742205226289,
        "requestStart": 1742205226323,
        "responseStart": 1742205226969,
        "responseEnd": 1742205226972,
        "unloadEventStart": 1742205226975,
        "unloadEventEnd": 1742205226975,
        "domLoading": 1742205226980,
        "domInteractive": 1742205227044,
        "domContentLoadedEventStart": 1742205227437,
        "domContentLoadedEventEnd": 1742205227437,
        "domComplete": 0,
        "loadEventStart": 0,
        "loadEventEnd": 0
      }
    },
    {
      "schema": "iglu:org.ietf/http_client_hints/jsonschema/1-0-0",
      "data": {
        "isMobile": false,
        "brands": [
          {
            "brand": "Chromium",
            "version": "134"
          },
          {
            "brand": "Not:A-Brand",
            "version": "24"
          },
          {
            "brand": "Google Chrome",
            "version": "134"
          }
        ]
      }
    }
  ]
}
```

### Page Ping

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4",
  "data": [
    {
      "e": "pp",
      "url": "https://gitlab.com/",
      "page": "GitLab",
      "refr": "https://gitlab.com/",
      "eid": "ac958a76-5360-44e1-a9f3-8172d6df0f80",
      "tv": "js-3.24.2",
      "tna": "gl",
      "aid": "gitlab",
      "p": "web",
      "cookie": "1",
      "cs": "UTF-8",
      "lang": "en-GB",
      "res": "1728x1117",
      "cd": "30",
      "tz": "Asia/Calcutta",
      "dtm": "1742205324496",
      "vp": "1920x331",
      "ds": "1920x1694",
      "vid": "720",
      "sid": "1574509e-5d6d-43d1-9e76-e42801ae2e55",
      "duid": "9e5500ac-3437-4457-a007-351911d54983",
      "cx": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy...",
      "stm": "1742205324501"
    }
  ]
}
```

### Self-describing Events

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4",
  "data": [
    {
      "e": "ue",
      "eid": "67ae8ec1-3ec0-46b7-89e0-fd944d90acc6",
      "tv": "js-3.24.2",
      "tna": "gl",
      "aid": "gitlab",
      "p": "web",
      "cookie": "1",
      "cs": "UTF-8",
      "lang": "en-GB",
      "res": "1728x1117",
      "cd": "30",
      "tz": "Asia/Calcutta",
      "dtm": "1742205393772",
      "vp": "1920x331",
      "ds": "1920x1694",
      "vid": "720",
      "sid": "1574509e-5d6d-43d1-9e76-e42801ae2e55",
      "duid": "9e5500ac-3437-4457-a007-351911d54983",
      "refr": "https://gitlab.com/",
      "url": "https://gitlab.com/",
      "ue_px": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy...",
      "cx": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy...",
      "stm": "1742205393774"
    }
  ]
}
```

This is part of link click tracking. The `ue_px` field is base64 encoded and contains the following JSON:

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0",
  "data": {
    "schema": "iglu:com.snowplowanalytics.snowplow/link_click/jsonschema/1-0-1",
    "data": {
      "targetUrl": "https://gitlab.com/",
      "elementId": "",
      "elementClasses": [
        "brand-logo"
      ],
      "elementTarget": ""
    }
  }
}
```

### Structured Events

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4",
  "data": [
    {
      "e": "se",
      "se_ca": "root:index",
      "se_ac": "render_duo_chat_callout",
      "eid": "12c18f54-ef65-489e-99f8-00922f9c3249",
      "tv": "js-3.24.2",
      "tna": "gl",
      "aid": "gitlab",
      "p": "web",
      "cookie": "1",
      "cs": "UTF-8",
      "lang": "en-GB",
      "res": "1728x1117",
      "cd": "30",
      "tz": "Asia/Calcutta",
      "dtm": "1742205394848",
      "vp": "1920x331",
      "ds": "1920x388",
      "vid": "720",
      "sid": "1574509e-5d6d-43d1-9e76-e42801ae2e55",
      "duid": "9e5500ac-3437-4457-a007-351911d54983",
      "refr": "https://gitlab.com/",
      "url": "https://gitlab.com/",
      "cx": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy...",
      "stm": "1742205395080"
    }
  ]
}
```

### Backend Events

```json
{
        "e": "se",
        "eid": "2e78c447-c18e-4087-a3a8-35723ecfb602",
        "aid": "asdfsadf",
        "cx": "eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy...",
        "tna": "gl",
        "stm": "1742268163018",
        "tv": "rb-0.8.0",
        "se_ac": "perform_action",
        "se_la": "redis_hll_counters.manage.unique_active_users_monthly",
        "se_ca": "Users::ActivityService",
        "p": "srv",
        "dtm": "1742268163016"
      }
```

cx field is base64 encoded and contains the following JSON:

```json
{
  "schema": "iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1",
  "data": [
    {
      "schema": "iglu:com.gitlab/gitlab_standard/jsonschema/1-1-1",
      "data": {
        "environment": "development",
        "source": "gitlab-rails",
        "correlation_id": "01JPKMCRCBSMB07DPGVSJJ708F",
        "plan": null,
        "extra": {},
        "user_id": 1,
        "global_user_id": "KaAjqePKpCsnc6P40up8ZOi4+BUwEUIyab6W5jWIg5M=",
        "is_gitlab_team_member": null,
        "namespace_id": null,
        "project_id": null,
        "feature_enabled_by_namespace_ids": null,
        "realm": "self-managed",
        "instance_id": "e1baa3de-7e45-4fbc-b17e-95995935cf09",
        "host_name": "nbelokolodov--20220811-Y26WJ",
        "instance_version": "17.10.0",
        "context_generated_at": "2025-03-18 03:22:43 UTC"
      }
    },
    {
      "schema": "iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-1",
      "data": {
        "data_source": "redis_hll",
        "event_name": "unique_active_user"
      }
    }
  ]
}
```
