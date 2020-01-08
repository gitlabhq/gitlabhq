---
type: reference
---

# GitLab application limits

GitLab, like most large applications, enforces limits within certain features to maintain a
minimum quality of performance. Allowing some features to be limitless could affect security,
performance, data, or could even exhaust the allocated resources for the application.

## Number of comments per issue, merge request or commit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/22388) in GitLab 12.4.

There's a limit to the number of comments that can be submitted on an issue,
merge request, or commit. When the limit is reached, system notes can still be
added so that the history of events is not lost, but user-submitted comments
will fail.

- **Max limit:** 5.000 comments
