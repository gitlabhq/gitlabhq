---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SPDX license list import Rake task
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

GitLab provides a Rake task for uploading a fresh copy of the [SPDX license list](https://spdx.org/licenses/)
to a GitLab instance. This list is needed for matching the names of [License approval policies](../user/compliance/license_approval_policies.md).

To import a fresh copy of the PDX license list, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:spdx:import

# source installations
bundle exec rake gitlab:spdx:import RAILS_ENV=production
```

To perform this task in the [offline environment](../user/application_security/offline_deployments/_index.md#defining-offline-environments),
an outbound connection to [`licenses.json`](https://spdx.org/licenses/licenses.json) should be
allowed.
