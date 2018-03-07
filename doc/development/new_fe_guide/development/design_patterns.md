# Design patterns

## Mediator

The [mediator pattern][mediator-pattern] is a common design pattern used in GitLab frontend to ensure that a single network request can update the store of two or more different Vue apps. Each page on GitLab is made up of multiple Vue apps and each app has it's own separate concerns. However, sometimes these Vue app's leverage the same network request to fetch data (E.g. Issuable sidebar items). In these cases, it would be ideal to take advantage of the mediator pattern, so that only one network request is needed to fetch the data, rather than one network request for each Vue app on the page.

## Creating features that update realtime

We use polling to simulate realtime features at GitLab. Here is the general architecture setup.

- Backend will include `Poll-Interval` in the response header. This will dictate the interval at which to poll from the frontend.
- Use [poll.js][poll-js] to manage the polling intervals.
- Use [Visibility.js][visibility-js] to manage polling on active browser tabs

Polling should be disabled when the following responses are received from the backend:
- `Poll-Interval: -1`
- HTTP status of `4XX` or `5XX`

## Running code

> TODO: Add Info

## Implementing Vue

> TODO: Add Info

> TODO: Grab data from backend using data attributes

[mediator-pattern]: https://en.wikipedia.org/wiki/Mediator_pattern
[poll-js]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/lib/utils/poll.js
[visibility-js]: https://github.com/ai/visibilityjs
