---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Snowplow review guidelines

This page includes introductory material for a
[Product Intelligence](https://about.gitlab.com/handbook/engineering/development/growth/product-intelligence/)
review, and is specific to Snowplow related reviews. For broader advice and
general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Resources for reviewers

- [Snowplow Guide](index.md)
- [Event Dictionary](dictionary.md)

## Review process

We recommend a Product Intelligence review when a merge request (MR) involves changes in
events or touches Snowplow related files.

### Roles and process

#### The merge request **author** should

- For frontend events, when relevant, add a screenshot of the event in
  the [testing tool](../snowplow/index.md#developing-and-testing-snowplow) used.
- For backend events, when relevant, add the output of the
  [Snowplow Micro](index.md#snowplow-mini) good events
  `GET http://localhost:9090/micro/good` (it might be a good idea
  to reset with `GET http://localhost:9090/micro/reset` first).
- Update the [Event Dictionary](event_dictionary_guide.md).

#### The Product Intelligence **reviewer** should

- Check that the [event taxonomy](../snowplow/index.md#structured-event-taxonomy) is correct.
- Check the [usage recommendations](../snowplow/index.md#usage-recommendations).
- Check that the [Event Dictionary](event_dictionary_guide.md) is up-to-date.
- If needed, check that the events are firing locally using one of the
[testing tools](../snowplow/index.md#developing-and-testing-snowplow) available.
- Approve the MR, and relabel the MR with `~"product intelligence::approved"`.
