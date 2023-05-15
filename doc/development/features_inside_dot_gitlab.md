---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Features inside the `.gitlab/` directory

We have implemented standard features that depend on configuration files in the `.gitlab/` directory. You can find `.gitlab/` in various GitLab repositories.
When implementing new features, please refer to these existing features to avoid conflicts:

- [Issue Templates](../user/project/description_templates.md#create-an-issue-template): `.gitlab/issue_templates/`.
- [Merge request Templates](../user/project/description_templates.md#create-a-merge-request-template): `.gitlab/merge_request_templates/`.
- [GitLab agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/configuration_repository.md#layout): `.gitlab/agents/`.
- [CODEOWNERS](../user/project/codeowners/index.md#set-up-code-owners): `.gitlab/CODEOWNERS`.
- [Route Maps](../ci/review_apps/index.md#route-maps): `.gitlab/route-map.yml`.
- [Customize Auto DevOps Helm Values](../topics/autodevops/customize.md#customize-helm-chart-values): `.gitlab/auto-deploy-values.yaml`.
- [Insights](../user/project/insights/index.md#configure-project-insights): `.gitlab/insights.yml`.
- [Service Desk Templates](../user/project/service_desk.md#create-customized-email-templates): `.gitlab/service_desk_templates/`.
