---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ServiceNow
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

ServiceNow offers several integrations to help centralize and automate your
management of GitLab workflows.

To simplify your stack and streamline your processes, you should use GitLab [deployment approvals](../../api/oauth2.md) whenever possible.

## GitLab spoke

With the GitLab spoke in ServiceNow, you can automate actions for GitLab
projects, groups, users, issues, merge requests, branches, and repositories.

For a full list of features, see the
[GitLab spoke documentation (Xanadu Release)](https://docs.servicenow.com/bundle/xanadu-integrate-applications/page/administer/integrationhub-store-spokes/concept/gitlab-spoke.html).

You must [configure GitLab as an OAuth2 authentication service provider](../../integration/oauth_provider.md),
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
- [ServiceNow DevOps documentation](https://docs.servicenow.com/bundle/tokyo-devops/page/product/enterprise-dev-ops/concept/dev-ops-bundle-landing-page.html)
- [GitLab SCM and Continuous Integration for DevOps](https://store.servicenow.com/sn_appstore_store.do#!/store/application/54dc4eacdbc2dcd02805320b7c96191e/)
