# Design patterns

## Mediator

The [mediator pattern][mediator-pattern] is a common design pattern used in GitLab frontend to ensure that a single network request can update the store of two or more different Vue apps.

Each page on GitLab is made up of multiple Vue apps and each app has it's own separate concerns. However, sometimes these Vue app's leverage the same network request to fetch data (E.g. Issuable sidebar items). In these cases, it would be ideal to take advantage of the mediator pattern, so that only one network request is needed to fetch the data, rather than one network request for each Vue app on the page.

<script src="https://unpkg.com/mermaid@7.1.2/dist/mermaid.min.js"></script>
<script>mermaid.initialize({startOnLoad:true});</script>
**Without Mediator**
<div class="mermaid">
graph TD
    A(Vue App 1's service) -- fetches --> C(API endpoint)
    B(Vue App 2's service) -- fetches --> D(API endpoint)
</div>

**With Mediator**
<div class="mermaid">
graph TD
    A(Vue App 1's service) -- fetches --> C(Vue App 1 and 2's mediator)
    B(Vue App 2's service) -- fetches --> C(Vue App 1 and 2's mediator)
    C(Common mediator) -- fetches -->D(API endpoint)
</div>

## Realtime features

We use polling to simulate realtime features at GitLab. Here is the general architecture setup.

- Backend will include `Poll-Interval` in the response header. This will dictate the interval at which to poll from the frontend.
- Use [poll.js][poll-js] to manage the polling intervals.
- Use [Visibility.js][visibility-js] to manage polling on active browser tabs

Polling should be disabled when the following responses are received from the backend:
- `Poll-Interval: -1`
- HTTP status of `4XX` or `5XX`

## Configuring new scripts to run on specific pages

> TODO: Add Content

## Vue features

> TODO: Add Content

### Folder Structure

All Vue features should follow a similar folder structure as the one listed below.

```
new_feature
├── components
│   └── new_feature.vue
│   └── ...
├── store
│  └── new_feature_store.js
├── service
│  └── new_feature_service.js
└── new_feature_bundle.js
```

#### Bundle file

This bundle file should include the root Vue instance of the new feature. The Store and Service should be imported, initialized and provided as a prop to the main component.

#### Store

We follow the [Flux architecture][flux-architecture] for all Vue features. Flux follows the unidirectional data flow pattern and is easier to maintain and debug.
We have two methods for implementing Flux.

1. Vue store pattern
2. Vuex

##### Vue store pattern

> TODO: Add Content

##### Vuex

> TODO: Add Content

[mediator-pattern]: https://en.wikipedia.org/wiki/Mediator_pattern
[poll-js]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/lib/utils/poll.js
[visibility-js]: https://github.com/ai/visibilityjs
[flux-architecture]: https://facebook.github.io/flux
