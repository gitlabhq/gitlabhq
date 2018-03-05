# Design patterns

## Mediator

> TODO: Add Info

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



[poll-js]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/lib/utils/poll.js
[visibility-js]: https://github.com/ai/visibilityjs
