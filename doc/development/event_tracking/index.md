# Event tracking

At GitLab, we encourage event tracking so we can iterate on and improve the project and user experience.

We do this by running experiments, and collecting analytics for features and feature variations. This is:

- So we generally know engagement.
- A way to approach A/B testing.

As developers, we should attempt to add tracking and instrumentation where possible. This enables the Product team to better understand:

- User engagement.
- Usage patterns.
- Other metrics that can potentially be improved on.

To maintain consistency, and not adversely effect performance, we have some basic tracking functionality exposed at both the frontend and backend layers that can be utilized while building new features or updating existing features.

We also encourage users to enable tracking, and we embrace full transparency with our tracking approach so it can be easily understood and trusted. By enabling tracking, users can:

- Contribute back to the wider community.
- Help GitLab improve on the product.

## Implementing tracking

Event tracking can be implemented on either the frontend or the backend layers, and each can be approached slightly differently since they have slightly different concerns.

In GitLab, many actions can be initiated via the web interface, but they can also be initiated via an API client (an iOS applications is a good example of this), or via `git` directly. Crucially, this means that tracking should be considered holistically for the feature that's being instrumented.

The data team should be involved when defining analytics and can be consulted when coming up with ways of presenting data that's being tracked. This allows our event data to be considered carefully and presented in ways that may reveal details about user engagement that may not be fully understood or interactions where we can make improvements. You can [contact the data team](https://about.gitlab.com/handbook/business-ops/data-team/#contact-us) and consult with them when defining tracking strategies.

### Frontend

Generally speaking, the frontend can track user actions and events, like:

- Clicking links or buttons.
- Submitting forms.
- Other typically interface-driven actions.

See [Frontend tracking guide](frontend.md).

### Backend

From the backend, the events that are tracked will likely consist of things like the creation or deletion of records and other events that might be triggered from layers that aren't necessarily only available in the interface.

See [Backend tracking guide](backend.md).

## Enabling tracking

Tracking can be enabled at:

- The instance level, which will enable tracking on both the frontend and backend layers.
- User level, though user tracking can be disabled on a per-user basis. GitLab tracking respects the [Do Not Track](https://www.eff.org/issues/do-not-track) standard, so any user who has enabled the Do Not Track option in their browser will also not be tracked from a user level.

We utilize Snowplow for the majority of our tracking strategy, and it can be enabled by navigating to:

- **Admin area > Settings > Integrations** in the UI.
- `admin/application_settings/integrations` in your browser.

The following configuration is required:

| Name          | Value                     |
| ------------- | ------------------------- |
| Collector     | `snowplow.trx.gitlab.net` |
| Site ID       | `gitlab`                  |
| Cookie domain | `.gitlab.com`             |

Once enabled, tracking events can be inspected locally by either:

- Looking at the network panel of the browser's development tools
- Using the [Snowplow Chrome Extension](https://chrome.google.com/webstore/detail/snowplow-inspector/maplkdomeamdlngconidoefjpogkmljm).
