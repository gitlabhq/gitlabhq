---
status: ongoing
creation-date: "2023-11-23"
authors: [ "@Andysoiron", "@g.hickman", "@mcavoj" ]
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
The new policy type Pipeline Execution Policy allows users to define custom CI jobs that will be injected into the project CI pipeline as well. We want to generalize the security policy
approach to provide the same flexibility that [compliance framework](../../../user/group/compliance_frameworks.md) needs. The combination of the 2 features
means that security policies can be scope to compliance frameworks and enforce the presence of custom CI jobs.

Like Scan Execution Policies, Pipeline Execution Policy jobs can be
[scoped](../../../user/application_security/policies/scan-execution-policies.md#policy_scope-scope-type)
to certain compliance frameworks applied to the project.
It should be possible to control when the policy jobs are enforced by using the existing [workflow rules](../../../ci/yaml/workflow.md).
Users can leverage one of the predefined security-policy stages to position jobs in the pipeline according to their needs.
Transitioning from compliance pipelines to the new feature should be as smooth as possible.

## Design and Implementation Details

### Pipeline Execution Policy MVC

The Pipeline Execution Policy MVC will allow the transition from compliance pipelines.

- It should be possible to add custom CI YAML to a security policy. For simplicity, the custom CI YAML should support the same configuration and follow the same schema as `.gitlab-ci.yml` files. The custom CI will be merged with the project CI when a pipeline starts.
- The security policy schema should allow the custom CI to be defined in an external file by allowing a project and file path to be added.
- Pipeline Execution Policies should execute custom CI YAML by creating jobs in isolated pipelines which are merged into the pipeline of the target projects.
- Organizations may require different CI configurations/templates to enforce globally for various use cases. Commonly, some projects focus on code and do not perform deployment. These projects may have different security/compliance requirements compared to other projects that facilitate the build and deployment steps. Pipeline execution policies must be able to support this need, allowing for variable configuration dependent on the type of project. Thus, it may be necessary to support more than one pipeline execution policy per level (e.g., more than one policy at the group level). However, we may be able to leverage policy scopes to limit the number of configurations enforced per level against a single project.
- When considering pipeline execution policy limits, another use case is hierarchical enforcement. Policies may be enforced globally (defined in one top-level group and enforcing all other groups/projects). Policies may also be enforced a tier lower in the business, such as via individual business units. Each BU may have unique requirements to satisfy. While we want to limit the opportunity for collision, we may be able to identify a solution that satisfies the need for top-down enforcement. Some customers have been exploring mechanisms for appending/extending policy enforcement down the tree/hierarchy. We could also start with lower limits, ensuring that top-level groups and sub-groups higher in the tree take precedence over projects or lower-tier subgroups.
- At minimum, Pipeline Execution Policy jobs should align with [existing CI variable precedence](../../../ci/variables/index.md#cicd-variable-precedence).
  Ideally, Pipeline Execution Policy jobs should not get any user-defined variables except those defined in the group or project where the policy belongs.
- Jobs should be executed in a way that is visible to users within the pipeline and that will not allow project jobs to override the policy jobs. In Scan Execution Policies today, we utilize the index pattern (-0,-1,-2,...) to increment the name of the job if a job of the same name exists. This also gives some minor indication of which jobs are executed by a security policy. For Pipeline Execution Policy jobs, the same pattern should be utilized.
- Jobs coming from the policies should be marked as such in the database so that they can be distinguished, for example by using build metadata. This allows for different handling of jobs and the corresponding variables by the runner.
- Users should be able to define the stage in which their job will run, and Pipeline Execution Policies will have a method to handle precedence. For example, a security/compliance team may want to enforce jobs that run commonly after a build stage. The stages and jobs must not interfere with those defined by development teams once enforced by a Pipeline Execution Policy.
- Pipeline Execution Policies should allow for jobs to be enforced in projects that do not contain an existing CI configuration.
- To reduce complexity, the `content` of a Pipeline Execution Policy can only be an inclusion of a single [CI file from a project](../../../ci/yaml/index.md#includeproject).

MVC syntax example:

```yaml
type: pipeline_execution_policy
name: PEP example
description: 'PEP example'
enabled: true
pipeline_config_strategy: inject_ci
content:
  include:
    - project: namespace-path/project-path
      file: policy_ci.yml
      ref: main
```

### Stages management strategy

We want users to be able to place jobs to run before or after certain CI stages of the project pipeline.
To achieve this, we want to introduce 2 reserved stages that can be used only by pipeline execution policies and injected into the project pipeline:

1. `.pipeline-policy-pre` stage will run at the very beginning of the pipeline, before the `.pre` stage.
1. `.pipeline-policy-post` stage will run at the very end of the pipeline, after the `.post` stage.

Injecting jobs in any of these stages is guaranteed to always work. Execution policy jobs can also be assigned to any standard (`build`, `test`, `deploy`) or user-declared stages. However, in this case, the jobs may be ignored depending on the project pipeline configuration.

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

- [Pipeline Execution Policy Type](https://gitlab.com/groups/gitlab-org/-/epics/13266#top)
- [Pipeline Execution Action (Custom CI YAML Support) for Scan Execution Policy Type](https://gitlab.com/groups/gitlab-org/-/epics/7312)
