---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# ServiceNow integration **(FREE)**

ServiceNow offers several integrations to help centralize and automate your
management of GitLab workflows.

## GitLab spoke

With the GitLab spoke in ServiceNow, you can automate actions for GitLab
projects, groups, users, issues, merge requests, branches, and repositories.

For a full list of features, see the
[GitLab spoke documentation](https://docs.servicenow.com/bundle/orlando-servicenow-platform/page/administer/integrationhub-store-spokes/concept/gitlab-spoke.html).

You must [configure GitLab as an OAuth2 authentication service provider](../../../integration/oauth_provider.md),
which involves creating an application and then providing the Application ID
and Secret in ServiceNow.

## GitLab SCM and Continuous Integration for DevOps

In ServiceNow DevOps, you can integrate with GitLab repositories and GitLab CI/CD
to centralize your view of GitLab activity and your change management processes.
You can:

- Track information about activity in GitLab repositories and CI/CD pipelines in
  ServiceNow.
- Integrate with GitLab CI/CD pipelines, by automating the creation of change
  tickets and determining criteria for changes to auto-approve.

For more information, refer to the following ServiceNow resources:

- [ServiceNow DevOps home page](https://www.servicenow.com/products/devops.html)
- [Install DevOps](https://docs.servicenow.com/bundle/paris-devops/page/product/enterprise-dev-ops/task/activate-dev-ops.html)
- [Install DevOps Integrations](https://docs.servicenow.com/bundle/paris-devops/page/product/enterprise-dev-ops/task/activate-dev-ops-integrations.html)
- [GitLab SCM and Continuous Integration for DevOps](https://store.servicenow.com/sn_appstore_store.do#!/store/application/54dc4eacdbc2dcd02805320b7c96191e/)
- [Model a GitLab CI pipeline in DevOps](https://docs.servicenow.com/bundle/paris-devops/page/product/enterprise-dev-ops/task/model-gitlab-pipeline-dev-ops.html).
