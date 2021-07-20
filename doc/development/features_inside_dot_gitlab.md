---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Features inside the `.gitlab/` directory

We have implemented standard features that depend on configuration files in the `.gitlab/` directory. You can find `.gitlab/` in various GitLab repositories.
When implementing new features, please refer to these existing features to avoid conflicts:

- [Custom Dashboards](../operations/metrics/dashboards/index.md#add-a-new-dashboard-to-your-project): `.gitlab/dashboards/`.
- [Issue Templates](../user/project/description_templates.md#create-an-issue-template): `.gitlab/issue_templates/`.
- [Merge Request Templates](../user/project/description_templates.md#create-a-merge-request-template): `.gitlab/merge_request_templates/`.
- [GitLab Kubernetes Agents](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/configuration_repository.md#layout): `.gitlab/agents/`.
- [CODEOWNERS](../user/project/code_owners.md#set-up-code-owners): `.gitlab/CODEOWNERS`.
- [Route Maps](../ci/review_apps/#route-maps): `.gitlab/route-map.yml`.
- [Customize Auto DevOps Helm Values](../topics/autodevops/customize.md#customize-values-for-helm-chart): `.gitlab/auto-deploy-values.yaml`.
- [GitLab managed apps CI/CD](../user/clusters/applications.md#usage): `.gitlab/managed-apps/config.yaml`.
- [Insights](../user/project/insights/index.md#configure-your-insights): `.gitlab/insights.yml`.
- [Service Desk Templates](../user/project/service_desk.md#using-customized-email-templates): `.gitlab/service_desk_templates/`.
- [Web IDE](../user/project/web_ide/#web-ide-configuration-file): `.gitlab/.gitlab-webide.yml`.
