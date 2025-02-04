---
stage: Platforms
group: Scalability
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Rails request SLIs (service level indicators)
---

NOTE:
This SLI is used for service monitoring. But not for [error budgets for stage groups](../stage_group_observability/_index.md#error-budget)
by default.

The request Apdex SLI and the error rate SLI are [SLIs defined in the application](_index.md).

The request Apdex measures the duration of successful requests as an indicator for
application performance. This includes the REST and GraphQL API, and the
regular controller endpoints.

The error rate measures unsuccessful requests as an indicator for
server misbehavior. This includes the REST API, and the
regular controller endpoints.

1. `gitlab_sli_rails_request_apdex_total`: This counter gets
   incremented for every request that did not result in a response
   with a `5xx` status code. It ensures slow failures are not
   counted twice, because the request is already counted in the error SLI.

1. `gitlab_sli_rails_request_apdex_success_total`: This counter gets
   incremented for every successful request that performed faster than
   the [defined target duration depending on the endpoint's urgency](#adjusting-request-urgency).

1. `gitlab_sli_rails_request_error_total`: This counter gets
   incremented for every request that resulted in a response
   with a `5xx` status code.

1. `gitlab_sli_rails_request_total`: This counter gets
   incremented for every request.

These counters are labeled with:

1. `endpoint_id`: The identification of the Rails Controller or the
   Grape-API endpoint.

1. `feature_category`: The feature category specified for that
   controller or API endpoint.

## Request Apdex SLO

These counters can be combined into a success ratio. The objective for
this ratio is defined in the service catalog per service. For this SLI to meet SLO,
the ratio recorded must be higher than:

- [Web: 0.998](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/web.jsonnet#L19)
- [API: 0.995](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/api.jsonnet#L19)
- [Git: 0.998](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/git.jsonnet#L22)

For example: for the web-service, we want at least 99.8% of requests
to be faster than their target duration.

We use these targets for alerting and service monitoring. Set durations taking
these targets into account, so we don't cause alerts. The goal, however, is to
set the urgency to a target that satisfies our users.

Both successful measurements and unsuccessful ones affect the
error budget for stage groups.

## Adjusting request urgency

Not all endpoints perform the same type of work, so it is possible to
define different urgency levels for different endpoints. An endpoint with a
lower urgency can have a longer request duration than endpoints with high urgency.

Long-running requests are more expensive for our infrastructure. While serving
one request, the thread remains occupied for the duration of that request. The thread
can handle nothing else. Due to Ruby's Global VM Lock, the thread might keep the
lock and stall other requests handled by the same Puma worker
process. The request is, in fact, a noisy neighbor for other requests
handled by the worker. We cap the upper bound for a target duration at 5 seconds
for this reason.

## Decreasing the urgency (setting a higher target duration)

You can decrease the urgency on an existing endpoint on
a case-by-case basis. Take the following into account:

1. Apdex is about perceived performance. If a user is actively waiting
   for the result of a request, waiting 5 seconds might not be
   acceptable. However, if the endpoint is used by an automation
   requiring a lot of data, 5 seconds could be acceptable.

   A product manager can help to identify how an endpoint is used.

1. The workload for some endpoints can sometimes differ greatly
   depending on the parameters specified by the caller. The urgency
   needs to accommodate those differences. In some cases, you could
   define a separate [application SLI](_index.md#defining-a-new-sli)
   for what the endpoint is doing.

   When the endpoints in certain cases turn into no-ops, making them
   very fast, we should ignore these fast requests when setting the
   target. For example, if the `MergeRequests::DraftsController` is
   hit for every merge request being viewed, but rarely renders
   anything, then we should pick the target that
   would still accommodate the endpoint performing work.

1. Consider the dependent resources consumed by the endpoint. If the endpoint
   loads a lot of data from Gitaly or the database, and this causes
   unsatisfactory performance, consider optimizing the
   way the data is loaded rather than increasing the target duration
   by lowering the urgency.

   In these cases, it might be appropriate to temporarily decrease
   urgency to make the endpoint meet SLO, if this is bearable for the
   infrastructure. In such cases, create a code comment linking to an issue.

   If the endpoint consumes a lot of CPU time, we should also consider
   this: these kinds of requests are the kind of noisy neighbors we
   should try to keep as short as possible.

1. Traffic characteristics should also be taken into account. If the
   traffic to the endpoint sometimes bursts, like CI traffic spinning up a
   big batch of jobs hitting the same endpoint, then having these
   endpoints take five seconds is unacceptable from an infrastructure point of
   view. We cannot scale up the fleet fast enough to accommodate for
   the incoming slow requests alongside the regular traffic.

When lowering the urgency for an existing endpoint, involve a
[Scalability team member](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/scalability/)
in the review. We can use request rates and durations available in the
logs to come up with a recommendation. You can pick a threshold
using the same process as for
[increasing urgency](#increasing-urgency-setting-a-lower-target-duration),
picking a duration that is higher than the SLO for the service.

We shouldn't set the longest durations on endpoints in the merge
requests that introduces them, because we don't yet have data to support
the decision.

## Increasing urgency (setting a lower target duration)

When increasing the urgency, we must make sure the endpoint
still meets SLO for the fleet that handles the request. You can use the
information in the logs to check:

1. Open [this table in Kibana](https://log.gprd.gitlab.net/goto/bbb6465c68eb83642269e64a467df3df)

1. The table loads information for the busiest endpoints by
   default. To speed the response, add both:

   - A filter for `json.meta.caller_id.keyword`.
   - The identifier you're interested in, for example:

     ```ruby
     Projects::RawController#show
     ```

     or:

     ```plaintext
     GET /api/:version/projects/:id/snippets/:snippet_id/raw
     ```

1. Check the [appropriate percentile duration](#request-apdex-slo) for
   the service handling the endpoint. The overall duration should
   be lower than your intended target.

1. If the overall duration is below the intended target, check the peaks over time
   in [this graph](https://log.gprd.gitlab.net/goto/9319c4a402461d204d13f3a4924a89fc)
   in Kibana. Here, the percentile in question should not peak above
   the target duration we want to set.

As decreasing a threshold too much could result in alerts for the
Apdex degradation, also involve a Scalability team member in
the merge request.

## How to adjust the urgency

You can specify urgency similar to how endpoints
[get a feature category](../feature_categorization/_index.md). Endpoints without a
specific target use the default urgency: 1s duration. These configurations
are available:

| Urgency    | Duration in seconds | Notes                                         |
|------------|---------------------|-----------------------------------------------|
| `:high`    | [0.25s](https://gitlab.com/gitlab-org/gitlab/-/blob/2f7a38fe48934b78f04233c4d2c81cde88a06da7/lib/gitlab/endpoint_attributes/config.rb#L8)               |                                               |
| `:medium`  | [0.5s](https://gitlab.com/gitlab-org/gitlab/-/blob/2f7a38fe48934b78f04233c4d2c81cde88a06da7/lib/gitlab/endpoint_attributes/config.rb#L9)                |                                               |
| `:default` | [1s](https://gitlab.com/gitlab-org/gitlab/-/blob/2f7a38fe48934b78f04233c4d2c81cde88a06da7/lib/gitlab/endpoint_attributes/config.rb#L10)                  | The default when nothing is specified.        |
| `:low`     | [5s](https://gitlab.com/gitlab-org/gitlab/-/blob/2f7a38fe48934b78f04233c4d2c81cde88a06da7/lib/gitlab/endpoint_attributes/config.rb#L11)                  |                                               |

### Rails controller

An urgency can be specified for all actions in a controller:

```ruby
class Boards::ListsController < ApplicationController
  urgency :high
end
```

To also specify the urgency for certain actions in a controller:

```ruby
class Boards::ListsController < ApplicationController
  urgency :high, [:index, :show]
end
```

A custom RSpec matcher is available to check endpoint's request urgency in the controller specs:

```ruby
specify do
   expect(get(:index, params: request_params)).to have_request_urgency(:medium)
end
```

### Grape endpoints

To specify the urgency for an entire API class:

```ruby
module API
  class Issues < ::API::Base
    urgency :low
  end
end
```

To specify the urgency also for certain actions in a API class:

```ruby
module API
  class Issues < ::API::Base
      urgency :medium, [
        '/groups/:id/issues',
        '/groups/:id/issues_statistics'
      ]
  end
end
```

Or, we can specify the urgency per endpoint:

```ruby
get 'client/features', urgency: :low do
  # endpoint logic
end
```

A custom RSpec matcher is also compatible with grape endpoints' specs:

```ruby

specify do
   expect(get(api('/avatar'), params: { email: 'public@example.com' })).to have_request_urgency(:medium)
end
```

WARNING:
We can't specify the urgency at the namespace level. The directive is ignored when doing so.

### Error budget attribution and ownership

This SLI is used for service level monitoring. It feeds into the
[error budget for stage groups](../stage_group_observability/_index.md#error-budget).

For more information, read the epic for
[defining custom SLIs and incorporating them into error budgets](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/525)).
The endpoints for the SLI feed into a group's error budget based on the
[feature category declared on it](../feature_categorization/_index.md).

To know which endpoints are included for your group, you can see the
request rates on the
[group dashboard for your group](https://dashboards.gitlab.net/dashboards/f/stage-groups/stage-groups).
In the **Budget Attribution** row, the **Puma Apdex** log link shows you
how many requests are not meeting a 1s or 5s target.

For more information about the content of the dashboard, see
[Dashboards for stage groups](../stage_group_observability/_index.md). For more information
about our exploration of the error budget itself, see
[issue 1365](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1365).
