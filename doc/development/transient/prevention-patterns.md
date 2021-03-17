---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Preventing Transient Bugs

This page will cover architectural patterns and tips for developers to follow to prevent [transient bugs.](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#transient-bugs)

## Common root causes

We've noticed a few root causes that come up frequently when addressing transient bugs.

- Needs better state management in the backend or frontend.
- Frontend code needs improvements.
- Lack of test coverage.
- Race conditions.

## Frontend

### Don't rely on response order

When working with multiple requests, it's easy to assume the order of the responses will match the order in which they are triggered.

That's not always the case and can cause bugs that only happen if the order is switched.

**Example:**

- `diffs_metadata.json` (lighter)
- `diffs_batch.json` (heavier)

If your feature requires data from both, ensure that the two have finished loading before working on it.

### Simulate slower connections when testing manually

Add a network condition template to your browser's developer tools to enable you to toggle between a slow and a fast connection.

**Example:**

- Turtle:
  - Down: 50kb/s
  - Up: 20kb/s
  - Latency: 10000ms

### Collapsed elements

When setting event listeners, if not possible to use event delegation, ensure all relevant event listeners are set for expanded content.

Including when that expanded content is:

- **Invisible** (`display: none;`). Some JavaScript requires the element to be visible to work properly, such as when taking measurements.
- **Dynamic content** (AJAX/DOM manipulation).

### Using assertions to detect transient bugs caused by unmet conditions

Transient bugs happen in the context of code that executes under the assumption
that the application's state meets one or more conditions. We may write a feature
that assumes a server-side API response always include a group of attributes or that
an operation only executes when the application has successfully transitioned to a new
state.

Transient bugs are difficult to debug because there isn't any mechanism that alerts
the user or the developer about unsatisfied conditions. These conditions are usually
not expressed explicitly in the code. A useful debugging technique for such situations
is placing assertions to make any assumption explicit. They can help detect the cause
which unmet condition causes the bug.

#### Asserting pre-conditions on state mutations

A common scenario that leads to transient bugs is when there is a polling service
that should mutate state only if a user operation is completed. We can use
assertions to make this pre-condition explicit:

```javascript
// This action is called by a polling service. It assumes that all pre-conditions
// are satisfied by the time the action is dispatched.
export const updateMergeableStatus = ({ commit }, payload) => {
  commit(types.SET_MERGEABLE_STATUS, payload);
};

// We can make any pre-condition explicit by adding an assertion
export const updateMergeableStatus = ({ state, commit }, payload) => {
  console.assert(
    state.isResolvingDiscussion === true,
    'Resolve discussion request must be completed before updating mergeable status'
  );
  commit(types.SET_MERGEABLE_STATUS, payload);
};
```

#### Asserting API contracts

Another useful way of using assertions is to detect if the response payload returned
by the server-side endpoint satisfies the API contract.

#### Related reading

[Debug it!](https://pragprog.com/titles/pbdp/debug-it/) explores techniques to diagnose
and fix non-determinstic bugs and write software that is easier to debug.

## Backend

### Sidekiq jobs with locks

When dealing with asynchronous work via Sidekiq, it is possible to have 2 jobs with the same arguments
getting worked on at the same time. If not handled correctly, this can result in an outdated or inaccurate state.

For instance, consider a worker that updates a state of an object. Before the worker updates the state
(for example, `#update_state`) of the object, it needs to check what the appropriate state should be
(for example, `#check_state`).

When there are 2 jobs being worked on at the same time, it is possible that the order of operations will go like:

1. (Worker A) Calls `#check_state`
1. (Worker B) Calls `#check_state`
1. (Worker B) Calls `#update_state`
1. (Worker A) Calls `#update_state`

In this example, `Worker B` is meant to set the updated status. But `Worker A` calls `#update_state` a little too late.

This can be avoided by utilizing either database locks or `Gitlab::ExclusiveLease`. This way, jobs will be
worked on one at a time. This also allows them to be marked as [idempotent](../sidekiq_style_guide.md#idempotent-jobs).

### Retry mechanism handling

There are times that an object/record will be on a failed state which can be rechecked.

If an object is in a state that can be rechecked, ensure that appropriate messaging is shown to the user
so they know what to do. Also, make sure that the retry functionality will be able to reset the state
correctly when triggered.

### Error Logging

Error logging doesn't necessarily directly prevents transient bugs but it can help to debug them.

When coding, sometimes we expect some exceptions to be raised and we rescue them.

Logging whenever we rescue an error helps in case it's causing transient bugs that a user may see.
While investigating a bug report, it may require the engineer to look into logs of when it happened.
Seeing an error being logged can be a signal of something that went wrong which can be handled differently.
