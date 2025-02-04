---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Client-side logging for frontend development
---

This guide contains the best practices for client-side logging for GitLab
frontend development.

## When to log to the browser console

We do not want to log unnecessarily to the browser console, as excessively
noisy console logs are not easy to read, parse, or process. We **do** want to
give visibility to unintended events in the system. If a possible but unexpected
exception occurs during runtime, we want to log the details of this exception.
These logs can give significantly helpful context to end users creating issues, or
contributors diagnosing problems.

Whenever a `catch(e)` exists, and `e` is something unexpected, log the details.

### What makes an error unexpected?

Sometimes a caught exception can be part of standard operations. For instance, third-party
libraries might throw an exception based on certain inputs. If we can gracefully
handle these exceptions, then they are expected. Don't log them noisily.
For example:

```javascript
try {
  // Here, we call a method based on some user input.
  // `doAThing` will throw an exception if the input is invalid.
  const userInput = getUserInput();
  doAThing(userInput);
} catch (e) {
  if (e instanceof FooSyntaxError) {
    // To handle a `FooSyntaxError`, we just need to instruct the user to change their input.
    // This isn't unexpected, and is part of standard operations.
    setUserMessage(`Try writing better code. ${e.message}`);
  } else {
    // We're not sure what `e` is, so something unexpected and bad happened...
    logError(e);
    setUserMessage('Something unexpected happened...');
  }
}
```

## How to log an error

We have a helpful `~/lib/logger` module which encapsulates how we can
consistently log runtime errors in GitLab. Import `logError` from this
module, and use it as you typically would `console.error`. Pass the actual `Error`
object, so the stack trace and other details can be captured in the log:

```javascript
// 1. Import the logger module.
import { logError } from '~/lib/logger';

export const doThing = () => {
  return foo()
    .then(() => {
      // ...
    })
    .catch(e => {
      // 2. Use `logError` like you would `console.error`.
      logError('An unexpected error occurred while doing the thing', e);

      // We may or may not want to present that something bad happened to the end user.
      showThingFailed();
    });
};
```

## Relation to frontend observability

Client-side logging is strongly related to
[Frontend observability](https://handbook.gitlab.com/handbook/company/working-groups/frontend-observability/).
We want unexpected errors to be observed by our monitoring systems, so
we can quickly react to user-facing issues. For a number of reasons, it is
unfeasible to send every log to the monitoring system. Don't shy away from using
`~/lib/logger`, but consider controlling which messages passed to `~/lib/logger`
are actually sent to the monitoring systems.

A cohesive logging module helps us control these side effects consistently
across the various entry points.
