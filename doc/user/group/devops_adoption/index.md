---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group DevOps Adoption **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321083) in GitLab 13.11.
> - [Deployed behind a feature flag](../../../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-group-devops-adoption).

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321083) in GitLab 13.11 as a [Beta feature](https://about.gitlab.com/handbook/product/gitlab-the-product/#beta).

To access Group DevOps Adoption, navigate to your group sidebar and select **Analytics > DevOps Adoption**

Group DevOps Adoption shows you how individual groups and sub-groups within your organization use the following features:

- Issues
- Merge Requests
- Approvals
- Runners
- Pipelines
- Deployments
- Scans

When managing groups in the UI, you can manage your sub-groups with the **Add/Remove sub-groups**
button, in the top right hand section of your Groups pages.

DevOps Adoption allows you to:

- Verify whether you are getting the return on investment that you expected from GitLab.
- Identify specific sub-groups that are lagging in their adoption of GitLab so you can help them along in their DevOps journey.
- Find the sub-groups that have adopted certain features and can provide guidance to other sub-groups on how to use those features.

![DevOps Report](img/group_devops_adoption_v13_11.png)

## Enable or disable Group DevOps Adoption **(ULTIMATE)**

Group DevOps Adoption is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:group_devops_adoption)
```

To disable it:

```ruby
Feature.disable(:group_devops_adoption)
```
