## Details
- **Feature Toggle Name**: `FEATURE_NAME`
- **Required GitLab Version**: `vX.X`

--------------------------------------------------------------------------------

## 1. Preparation

- [ ] **Controllers and workers**:
  1. Please link to dashboards of the workers, and the controllers and actions that can be impacted
  2. ...
  3. ...

## 2. Development Trial

#### Check Dev Server Versions
- [ ] GitLab: https://dev.gitlab.org/help

#### Enable on `dev.gitlab.org`:
- [ ] `/chatops feature set FEATURE_NAME true --dev` in [`#dev-gitlab`](https://gitlab.slack.com/messages/C6WQ87MU3)

Then leave running while monitoring and performing some testing through web, api or SSH.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Dev Sentry](https://sentry.gitlab.net/gitlab/devgitlaborg/?query=is%3Aunresolved)

## 3. Staging Trial

#### Check Staging Server Versions
- [ ] GitLab: https://staging.gitlab.com/help

#### Enable on `staging.gitlab.com`
- [ ] `/chatops run feature set FEATURE_NAME true --staging` in [`#development`](https://gitlab.slack.com/messages/C02PF508L/)

Then leave running while monitoring for at least **15 minutes** while performing some testing through web, api or SSH.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/?query=is%3Aunresolved)

## 4. Production Server Version Check

- [ ] GitLab: https://gitlab.com/help

## 5. Initial Impact Check

- [ ] Enable for a subset of users, when using percentage gates: 1%.

Then leave running while monitoring for at least **15 minutes** while performing some testing through web, api or SSH.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/?query=is%3Aunresolved)

## 6. Low Impact Check

- [ ] Enable for a bigger subset of users, when using percentage gates: 10%.

Then leave running while monitoring for at least **30 minutes** while performing some testing through web, api or SSH.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/?query=is%3Aunresolved)

## 7. Mid Impact Trial

- [ ] Enable for a big subset of users, when using percentage gates: 50%.

Then leave running while monitoring for at least **12 hours** while performing some testing through web, api or SSH.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Sentry](https://sentry.gitlab.net/gitlab/gitlabcom/?query=is%3Aunresolved)

## 8. Full Impact Trial

- [ ] Enable for all users: `/chatops run feature set FEATURE_NAME true

Then leave running while monitoring for at least **1 week**.

#### Monitor

- [ ] [Monitor Using Grafana](https://dashboards.gitlab.net)
- [ ] [Inspect logs in ELK](https://log.gitlab.net/app/kibana)
- [ ] [Check for errors in GitLab Dev Sentry](https://sentry.gitlab.net/gitlab/devgitlaborg/?query=is%3Aunresolved)

#### Success?

- [ ] Remove the feature gate from the code, and close this issue with that MR.
