---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SPDX license list import **(PREMIUM SELF)**

GitLab provides a Rake task for uploading a fresh copy of the [SPDX license list](https://spdx.org/licenses/)
to a GitLab instance. This list is needed for matching the names of [License Compliance policies](../user/compliance/license_compliance/index.md).

To import a fresh copy of the PDX license list, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:spdx:import

# source installations
bundle exec rake gitlab:spdx:import RAILS_ENV=production
```

To perform this task in the [offline environment](../user/application_security/offline_deployments/#defining-offline-environments),
an outbound connection to [`licenses.json`](https://spdx.org/licenses/licenses.json) should be
allowed.
