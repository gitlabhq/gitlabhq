---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Snowplow review guidelines

This page includes introductory material for a
[Product Intelligence](https://about.gitlab.com/handbook/engineering/development/analytics/product-intelligence/)
review, and is specific to Snowplow related reviews. For broader advice and
general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Resources for reviewers

- [Snowplow Guide](index.md)
- [Event Dictionary](https://metrics.gitlab.com/snowplow/)

## Review process

We recommend a Product Intelligence review when a merge request (MR) involves changes in
events or touches Snowplow related files.

### Roles and process

#### The merge request **author** should

- For frontend events, when relevant, add a screenshot of the event in
  the [testing tool](implementation.md#develop-and-test-snowplow) used.
- For backend events, when relevant, add the output of the
  [Snowplow Micro](implementation.md#test-backend-events-with-snowplow-micro) good events
  `GET http://localhost:9090/micro/good` (it might be a good idea
  to reset with `GET http://localhost:9090/micro/reset` first).
- Add or update the event definition file according to the [Event Dictionary Guide](event_dictionary_guide.md).

#### The Product Intelligence **reviewer** should

- Check that the [event schema](index.md#event-schema) is correct.
- Check the [usage recommendations](implementation.md#usage-recommendations).
- Check that an event definition file was created or updated in accordance with the [Event Dictionary Guide](event_dictionary_guide.md).
- If needed, check that the events are firing locally using one of the
[testing tools](implementation.md#develop-and-test-snowplow) available.
- Approve the MR, and relabel the MR with `~"product intelligence::approved"`.
- If the snowplow event mirrors a RedisHLL event, then tag @mdrussell to review if the payload is usable for this purpose.
