---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Features inside the `.gitlab/` directory
---

We have implemented standard features that depend on configuration files in the `.gitlab/` directory. You can find `.gitlab/` in various GitLab repositories.
When implementing new features, refer to these existing features to avoid conflicts:

- [Description templates](../user/project/description_templates.md#create-a-description-template): `.gitlab/issue_templates/`.
- [Merge request templates](../user/project/description_templates.md#create-a-merge-request-template): `.gitlab/merge_request_templates/`.
- [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent): `.gitlab/agents/`.
- [CODEOWNERS](../user/project/codeowners/_index.md#set-up-code-owners): `.gitlab/CODEOWNERS`.
- [Route Maps](../ci/review_apps/_index.md#route-maps): `.gitlab/route-map.yml`.
- [Customize Auto DevOps Helm Values](../topics/autodevops/customize.md#customize-helm-chart-values): `.gitlab/auto-deploy-values.yaml`.
- [Insights](../user/project/insights/_index.md#for-projects): `.gitlab/insights.yml`.
- [Service Desk Templates](../user/project/service_desk/configure.md#customize-emails-sent-to-external-participants): `.gitlab/service_desk_templates/`.
- [Secret Detection Custom Rulesets](../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets): `.gitlab/secret-detection-ruleset.toml`
- [Static Analysis Custom Rulesets](../user/application_security/sast/customize_rulesets.md#create-the-configuration-file): `.gitlab/sast-ruleset.toml`
