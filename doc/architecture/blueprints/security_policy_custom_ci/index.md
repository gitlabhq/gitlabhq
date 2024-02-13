---
status: ongoing
creation-date: "2023-11-23"
authors: [ "@Andysoiron", "@g.hickman" ]
coach: "@fabiopitino"
approvers: [ "@g.hickman" ]
owning-stage: "~devops::govern"
participating-stages: ["~devops::verify"]
---

# Pipeline Execution Policy

This document is a work in progress and represents the current state of the vision to allow users to enforce CI jobs to be run as part of project pipelines and enabling users to link/scope those jobs to projecs using security policies and compliance frameworks.

## Summary

Users need a single solution for enforcing jobs to be run as part of a project pipeline. They want a way to combine the flexibility of [compliance framework pipelines](../../../user/group/compliance_pipelines.md) with the simplicity of [scan execution policies](../../../user/application_security/policies/scan-execution-policies.md#scan-execution-policies-schema).

There are many cases that could be addressed using pipeline execution policies to define policy rules, but here are a few of the most common we've heard so far:

1. I want to include CI templates using `include` statements and be able to pull in templates such as `.latest` security scanner templates. See [CI templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).
1. I want to enforce execution of a 3rd party scanner, so that I can capture additional security results and manage them alongside results from GitLab scanners in the vulnerability report.
1. I want to enforce a custom script/check for compliance.
1. I want to enforce scanners to analyze code stored in GitLab, but call out to a 3rd party CI tool to continue a pipeline. A common case here may be for users migrating to GitLab, but some teams still may be using 3rd party CI tools in the meantime.
1. I want to export results from scanners to a 3rd party tool.
1. I want to block MRs until a UAT in an external tool is completed (quality gate), so that I can ensure the quality of changes to my production code.
1. I want to standardize custom project badges that can quickly communicate to users in a project which security policies are enabled and if pipelines are blocked by a given scan result, so that my security team and developer team can easily understand the security state of a project.
1. I want to create a custom badge in projects to communicate the security grade, so that team members are incentivized to keep their score high.

## Motivation

### Goals

1. Provide a proper replacement for compliance pipelines, with an objective of deprecating compliance pipelines in 16.9 and removal in 17.0.
1. Set up the architecture in a way that the feature can be enhanced to solve known compliance pipelines issues and customer pain points for enforcing scan execution globally across their organization.

Known compliance pipelines issues are:

- [Unable to support a project with an external config file or no config file](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#1-unable-to-support-a-project-with-an-external-config-file-or-no-config-file)
- [CI variables in the Compliance config can be overwritten](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#2-ci-variables-in-the-compliance-config-can-be-overwritten)
- [Compliance jobs can be overwritten by target repository](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#3-compliance-jobs-can-be-overwritten-by-target-repository)
- [Conflict with top-level global keywords](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#4-conflict-with-top-level-global-keywords-eg-stages)
- [Must ensure compliance jobs are always run](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#5-must-ensure-compliance-jobs-are-always-run)
- [Prefilled variables are not shown when manually starting pipeline](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#6-prefilled-variables-are-not-shown-when-manually-starting-pipeline)
- [Need to unify Scan Execution Policies and Compliance Framework](https://gitlab.com/gitlab-org/gitlab/-/issues/416104#7-need-to-unify-scan-execution-policies-and-compliance-framework)
- [Compliance Framework not found or access denied](https://gitlab.com/gitlab-org/gitlab/-/issues/404707)
- [Compliance pipeline jobs don't run in a specific situation due to GitLab only checking the project's pipeline configuration](https://gitlab.com/gitlab-org/gitlab/-/issues/412279)
- [.pre/.post jobs should be optionally allowed in empty pipelines](https://gitlab.com/gitlab-org/gitlab/-/issues/420339)
- [Allow compliance pipelines to hold constant any values that are set from an include file](https://gitlab.com/gitlab-org/gitlab/-/issues/365381)
- [Run Compliance Framework pipeline in MRs that originate in forks of the CF-labeled project](https://gitlab.com/gitlab-org/gitlab/-/issues/374099)
- [Compliance pipeline configuration in not exposed in merged_YAML](https://gitlab.com/gitlab-org/gitlab/-/issues/367247)

## Proposal

Currently, security policies can include multiple scan actions. Each scan action will result in a CI job that will be injected in the project CI pipeline.
The new feature allows you to define custom CI jobs that will be injected into the project CI pipeline as well. We want to generalize the security policy
approach to provide the same flexibility that [compliance framework](../../../user/group/compliance_frameworks.md) needs. The combination of the 2 features
means that security policies can be scope to compliance frameworks and enforce the presence of custom CI jobs.

Like scan execution policies, custom CI jobs can be scoped to certain branch names, branch types or compliance frameworks applied to the project.
Users can leverage one of the predefined security-policy stages to position jobs in the pipeline according to their needs.
Transitioning from compliance pipelines to the new feature should be as smooth as possible.

## Design and Implementation Details

### Pipeline Execution Policy MVC

The Pipeline Execution Policy MVC will allow the transition from compliance pipelines.

- It should be possible to add custom CI YAML to a security policy. The CI YAML should follow the same schema as `.gitlab-ci.yml` files. The custom CI will be merged with the project CI when a pipeline starts.
- The security policy schema should allow the custom CI to be defined in an external file by allowing a project and file path to be added.
- Scan execution policies should execute custom CI YAML similar to existing policies, by injecting the job into the GitLab CI YAML of the target projects.
- At minimum, pipeline execution policy jobs should align with [existing CI variable precedence](../../../ci/variables/index.md#cicd-variable-precedence). Ideally, all CI variables defined in a scan execution policy job should execute as highest precedence. Specifically, scan execution job variables should take precedence over project, group, and instance variables compliance project variables, among others.
- Jobs should be executed in a way that is visible to users within the pipeline and that will not allow project jobs to override the SEP jobs. In scan execution policies today, we utilize the index pattern (-0,-1,-2,...) to increment the name of the job if a job of the same name exists. This also gives some minor indication of which jobs are executed by a security policy. For custom YAML jobs, the same pattern should be utilized.
- Users should be able to define the stage in which their job will run, and scan execution policies will have a method to handle precedence. For example, a security/compliance team may define want to enforce jobs that run commonly after a build stage. They would be able to use build_after (for example) and scan execution policies would inject the build_after stage after the build stage and enforce the custom CI YAML defined in the pipeline execution policy within this stage. The stage and job cannot be interfered with by development teams once enforced by a scan execution policy. We should define the rules that allow for injecting stages cleanly into all enforced projects but be minimal invasive as to the project CI.
- Pipeline execution policies should execute custom CI YAML in projects that do not contain an existing CI configuration, the same as standard scan execution policies work today.

### Stages management strategy

We want users to be able to place jobs to run before or after certain CI stages of the project pipeline.
To achieve this, we want to introduce 3 reserved stages that can be used only by pipeline execution policies and injected into the project pipeline:

1. `.pipeline-policy-pre` stage will run at the very beginning of the pipeline, before the `.pre` stage.
1. `.pipeline-policy` stage will be injected after the `test` stage. If the `test` stage does not exist, it will be injected after the `build` stage. If the `build` stage does not exist, it will be injected at the beginning of the pipeline after the `.pre` stage.
1. `.pipeline-policy-post` stage will run at the very end of the pipeline, after the `.post` stage.

Injecting jobs in any of these 3 stages is guaranteed to always work. Execution policy jobs can also be assigned to any stage that exists in the project pipeline. In this case, however, it's not guaranteed that the injection always works as it depends whether the project pipeline has declared such stage.
It will not be possible to create custom stages in a pipeline execution policy.

We will try this approach as part of the experiment phase. We also discussed the following strategies that we might want to try:

#### 1. Make security policy stages order take precedence

Pipeline execution policies can modify stages by redefining them using the `stages` keyword.
The order of stages defined in the pipeline execution policy will take precedence over the order defined in the project CI.

If a pipeline execution policy wants to inject a job after the `test` stage, it can redefine stages as:

```yaml
stages:
  - test
  - policy_after_test
```

This solution provides flexibility to users as they can define custom stages. The downside is that there will be no single source of truth for the order of stages anymore.
If a project CI defines a custom stage that is not defined in the pipeline execution policy, we don't know if it should run before or after the pipeline execution policy stages.

#### 2. Introduce `pre` and `post` keywords

Security policies can use `pre_[stage_name]` and `post_[stage_name]` stages to inject jobs before or after certain stages. For example, `pre_test` would run before the `test` stage.
This way the security policy are unlikely to disrupt the project CI.
The downside is that the policy author needs to be aware of the stages used by projects and policy stages can be skipped by renaming the `test` stage to `test_2` for example.

#### 3. Introduce advanced stage rules

An advanced API for pipeline execution policy stages allows to inject stages depending on the existence of other stages. Schema example:

```yaml
compliance_stages:
- stage_name: qa
  after:
  - release
  if:
  - stage_exist: deploy
```

This will provide flexibility and allows users to define the behavior for different project CI stage setups.

#### 4. Run all jobs in a default stage

Jobs defined in a pipeline execution policy will run in the `pipeline-policy` stage. This stage will be injected after the `test` stage.
If the `test` stage doesn't exist, it will be injected after the `build` stage. If the `build` stage doesn't exist, it will be injected at the beginning of the pipeline.

## Links

- [Pipeline execution policy MVC epic](https://gitlab.com/groups/gitlab-org/-/epics/7312)
