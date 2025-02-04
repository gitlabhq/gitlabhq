---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sentry monitoring in the frontend development of GitLab
---

The GitLab Frontend team uses Sentry as an observability tool to monitor how the UI performs for
users on `gitlab.com`.

GitLab.com is configured to report to our Sentry instance at **Admin > Metrics and profiling > Sentry**.

We monitor two kinds of data: **Errors** and **Performance**.

NOTE:
The [Frontend Observability Working Group](https://handbook.gitlab.com/handbook/company/working-groups/frontend-observability/) is looking to improve how we use Sentry. GitLab team members can provide feedback at
[issue #427402](https://gitlab.com/gitlab-org/gitlab/-/issues/427402).

## Start using Sentry

Our Sentry instance is located at [https://new-sentry.gitlab.net/](https://new-sentry.gitlab.net/).
Only GitLab team members can access Sentry.

After your first sign in you can join the `#gitlab` team by selecting **Join a team**. Confirm that
`#gitlab` appears under `YOUR TEAMS` in the [teams page](https://new-sentry.gitlab.net/settings/gitlab/teams/).

## Error reporting

Errors, also known as "events" in the Sentry UI, are instances of abnormal or unexpected runtime
behavior that users experience in their browser.

GitLab uses the [Sentry Browser SDK](https://docs.sentry.io/platforms/javascript/) to report errors
to our Sentry instance under the project
[`gitlabcom-clientside`](https://new-sentry.gitlab.net/organizations/gitlab/projects/gitlabcom-clientside/?project=4).

### Reporting known errors

The most common way to report errors to Sentry is to call `captureException(error)`, for example:

```javascript
import * as Sentry from '~/sentry/sentry_browser_wrapper';

try {
  // Code that may fail in runtime
} catch (error) {
  Sentry.captureException(error)
}
```

**When should you report an error?** We want to avoid reporting errors that we either don't care
about, or have no control over. For example, we shouldn't report validation errors when a user fills
out a form incorrectly. However, if that form submission fails because or a server error,
this is an error we want Sentry to know about.

By default your local development instance does not have Sentry configured. Calls to Sentry are
stubbed and shown in the console with a `[Sentry stub]` prefix for debugging.

### Unhandled/unknown errors

Additionally, we capture unhandled errors automatically in all of our pages.

## Error Monitoring

Once errors are captured, they appear in Sentry. For example you can see the
[errors reported in the last 24 hours in canary and production](https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gprd-cny&environment=gprd&project=4&query=&referrer=issue-list&sort=freq&statsPeriod=24h).

In the list, select any error to see more details... and ideally propose a solution for it!

NOTE:
We suggest filtering errors by the environments `gprd` and `gprd-cny`, as there is some spam in our
environment data.

### Exploring error data

Team members can use Sentry's [Discover page](https://new-sentry.gitlab.net/organizations/gitlab/discover/homepage/?environment=gprd-cny&environment=gprd&field=title&field=event.type&field=project&field=user.display&field=timestamp&field=replayId&name=All+Events&project=4&query=&sort=-timestamp&statsPeriod=14d&yAxis=count%28%29) to find unexpected issues.

Additionally, we have created [a dashboard](https://new-sentry.gitlab.net/organizations/gitlab/dashboard/3/?environment=gprd&environment=gprd-cny&project=4&statsPeriod=24h) to report which feature categories and pages produce
most errors, among other data.

Engineering team members are encouraged to explore error data and find ways to reduce errors on our
user interface. Sentry also provides alerts for folks interested in getting notified when errors occur.

### Filtering errors

We receive several thousands of reports per day, so team members can filter errors based on their
work area.

We mark errors with two additional custom `tags` to help identify their source:

- `feature_category`: The feature area of the page. (For example, `code_review_workflow` or `continuous_integration`.) **Source:** `gon.feature_category`
- `page`: Identifier of method called in the controller to render the page. (For example, `projects:merge_requests:index` or `projects:pipelines:index`.) **Source:** [`body_data_page`](https://gitlab.com/gitlab-org/gitlab/blob/b2ea95b8b1f15228a2fd5fa3fbd316857d5676b8/app/helpers/application_helper.rb#L144).

Frontend engineering team members can filter errors relevant to their group and/or page.

## Performance Monitoring

We use [BrowserTracing](https://docs.sentry.io/platforms/javascript/performance/) to report performance metrics to Sentry.

You can visit [our performance data of the last 24 hours](https://new-sentry.gitlab.net/organizations/gitlab/performance/?environment=gprd-cny&environment=gprd&project=4&statsPeriod=24h) and use the filters to drill down and learn more.

## Sentry instance infrastructure

The GitLab infrastructure team manages the Sentry instance, you can find more details about its architecture and data management in its [runbook documentation](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/sentry/sentry.md).
