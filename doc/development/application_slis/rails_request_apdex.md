---
stage: Platforms
group: Scalability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rails request apdex SLI

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/525) in GitLab 14.4

NOTE:
This SLI is not yet used in [error budgets for stage
groups](../stage_group_dashboards.md#error-budget) or service
monitoring. This is being worked on in [this
project](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/573).

The request apdex SLI (Service Level Indicator) is [an SLI defined in the application](index.md)
that measures the duration of successful requests as an indicator for
application performance. This includes the REST and GraphQL API, and the
regular controller endpoints. It consists of these counters:

1. `gitlab_sli:rails_request_apdex:total`: This counter gets
   incremented for every request that did not result in a response
   with a 5xx status code. This means that slow failures don't get
   counted twice: The request is already counted in the error-SLI.

1. `gitlab_sli:rails_request_apdex:success_total`: This counter gets
   incremented for every successful request that performed faster than
   the [defined target duration depending on the endpoint's
   urgency](#adjusting-request-urgency).

Both these counters are labeled with:

1. `endpoint_id`: The identification of the Rails Controller or the
   Grape-API endpoint

1. `feature_category`: The feature category specified for that
   controller or API endpoint.

## Request Apdex SLO

These counters can be combined into a success ratio, the objective for
this ratio is defined in the service catalog per service:

1. [Web: 0.998](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/web.jsonnet#L19)
1. [API: 0.995](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/api.jsonnet#L19)
1. [Git: 0.998](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/services/git.jsonnet#L22)

This means that for this SLI to meet SLO, the ratio recorded needs to
be higher than those defined above.

For example: for the web-service, we want at least 99.8% of requests
to be faster than their target duration.

These are the targets we use for alerting and service montoring. So
durations should be set keeping those into account. So we would not
cause alerts. But the goal would be to set the urgency to a target
that users would be satisfied with.

Both successful measurements and unsuccessful ones have an impact on the
error budget for stage groups.

## Adjusting request urgency

Not all endpoints perform the same type of work, so it is possible to
define different urgencies for different endpoints. An endpoint with a
lower urgency can have a longer request duration than endpoints that
are high urgency.

Long-running requests are more expensive for our
infrastructure: while one request is being served, the thread remains
occupied for the duration of that request. So nothing else can be handled by that
thread. Because of Ruby's Global VM Lock, the thread might keep the
lock and stall other requests handled by the same Puma worker
process. The request is in fact a noisy neighbor for other requests
handled by the worker. This is why the upper bound for a target
duration is capped at 5 seconds.

## Decreasing the urgency (setting a higher target duration)

Decreasing the urgency on an existing endpoint can be done on
a case-by-case basis. Please take the following into account:

1. Apdex is about perceived performance, if a user is actively waiting
   for the result of a request, waiting 5 seconds might not be
   acceptable. While if the endpoint is used by an automation
   requiring a lot of data, 5 seconds could be okay.

   A product manager can help to identify how an endpoint is used.

1. The workload for some endpoints can sometimes differ greatly
   depending on the parameters specified by the caller. The urgency
   needs to accomodate that. In some cases, it might be interesting to
   define a separate [application SLI](index.md#defining-a-new-sli)
   for what the endpoint is doing.

   When the endpoints in certain cases turn into no-ops, making them
   very fast, we should ignore these fast requests when setting the
   target. For example, if the `MergeRequests::DraftsController` is
   hit for every merge request being viewed, but doesn't need to
   render anything in most cases, then we should pick the target that
   would still accomodate the endpoint performing work.

1. Consider the dependent resources consumed by the endpoint. If the endpoint
   loads a lot of data from Gitaly or the database and this is causing
   it to not perform satisfactory. It could be better to optimize the
   way the data is loaded rather than increasing the target duration
   by lowering the urgency.

   In cases like this, it might be appropriate to temporarily decrease
   urgency to make the endpoint meet SLO, if this is bearable for the
   infrastructure. In such cases, please link an issue from a code
   comment.

   If the endpoint consumes a lot of CPU time, we should also consider
   this: these kinds of requests are the kind of noisy neighbors we
   should try to keep as short as possible.

1. Traffic characteristics should also be taken into account: if the
   trafic to the endpoint is bursty, like CI traffic spinning up a
   big batch of jobs hitting the same endpoint, then having these
   endpoints take 5s is not acceptable from an infrastructure point of
   view. We cannot scale up the fleet fast enough to accomodate for
   the incoming slow requests alongside the regular traffic.

When lowering the urgency for an existing endpoint, please involve a
[Scalability team member](https://about.gitlab.com/handbook/engineering/infrastructure/team/scalability/#team-members)
in the review. We can use request rates and durations available in the
logs to come up with a recommendation. Picking a threshold can be done
using the same process as for [increasing
urgency](#increasing-urgency-setting-a-lower-target-duration), picking
a duration that is higher than the SLO for the service.

We shouldn't set the longest durations on endpoints in the merge
requests that introduces them, since we don't yet have data to support
the decision.

## Increasing urgency (setting a lower target duration)

When increasing the urgency, we need to make sure the endpoint
still meets SLO for the fleet that handles the request. You can use the
information in the logs to determine this:

1. Open [this table in
   Kibana](https://log.gprd.gitlab.net/goto/bbb6465c68eb83642269e64a467df3df)

1. The table loads information for the busiest endpoints by
   default. You can speed things up by adding a filter for
   `json.caller_id.keyword` and adding the identifier you're intersted
   in (for example: `Projects::RawController#show`).

1. Check the [appropriate percentile duration](#request-apdex-slo) for
   the service the endpoint is handled by. The overall duration should
   be lower than the target you intend to set.

1. Assess if the overall duration is below the intended target. Please also
   check the peaks over time in [this
   graph](https://log.gprd.gitlab.net/goto/9319c4a402461d204d13f3a4924a89fc)
   in Kibana. Here, the percentile in question should not peak above
   the target duration we want to set.

Since decreasing a threshold too much could result in alerts for the
apdex degradation, please also involve a Scalability team member in
the merge request.

## How to adjust the urgency

The urgency can be specified similar to how endpoints [get a feature
category](../feature_categorization/index.md).

For endpoints that don't have a specific target, the default urgency (1s duration) will be used.

The following configurations are available:

| Urgency  | Duration in seconds | Notes                                         |
|----------|---------------------|-----------------------------------------------|
| :high    | 0.25s               |                                               |
| :medium  | 0.5s                |                                               |
| :default | 1s                  | This is the default when nothing is specified |
| :low     | 5s                  |                                               |

### Rails controller

An urgency can be specified for all actions in a controller like this:

```ruby
class Boards::ListsController < ApplicationController
  urgency :high
end
```

To specify the urgency also for certain actions in a controller, they
can be specified like this:

```ruby
class Boards::ListsController < ApplicationController
  urgency :high, [:index, :show]
end
```

### Grape endpoints

To specify the urgency for an entire API class, this can be done as
follows:

```ruby
module API
  class Issues < ::API::Base
    urgency :low
  end
end
```

To specify the urgency also for certain actions in a API class, they
can be specified like this:

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
