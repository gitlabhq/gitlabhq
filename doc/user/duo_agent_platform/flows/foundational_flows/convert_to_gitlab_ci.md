---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert to GitLab CI/CD Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab 18.3 [with a flag](../../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci`. Disabled by default, but can be enabled for the instance or a user.
- Feature flag `duo_workflow_in_ci` enabled by default in GitLab 18.4. Feature flag `duo_workflow` must also be enabled, but it is enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flags `duo_workflow_in_ci` and `duo_workflow` removed in GitLab 18.9.

{{< /history >}}

The Convert to GitLab CI/CD Flow helps you migrate your Jenkins pipelines to GitLab CI/CD. This flow:

- Analyzes your existing Jenkins pipeline configuration.
- Converts Jenkins pipeline syntax to GitLab CI/CD YAML.
- Suggests best practices for GitLab CI/CD implementation.
- Creates a merge request with the converted pipeline configuration.
- Provides guidance on migrating Jenkins plugins to GitLab features.

This flow is available in the GitLab UI only.

> [!note]
> The Convert to GitLab CI/CD Flow creates merge requests by using a service account. Organizations with SOC 2, SOX, ISO 27001, or FedRAMP requirements should ensure appropriate peer review policies are in place. For more information, see [compliance considerations for merge requests](../../composite_identity.md#compliance-considerations-for-merge-requests).

## Prerequisites

To convert a Jenkinsfile, you must:

- Have access to your Jenkins pipeline configuration.
- Have the Developer, Maintainer, or Owner role in the target GitLab project.
- Meet [the other prerequisites](../../../duo_agent_platform/_index.md#prerequisites).
- [Ensure the GitLab Duo service account can create commits and branches](../../troubleshooting.md#session-is-stuck-in-created-state).
- Ensure that the Convert to GitLab CI/CD Flow is [turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off).

## Use the flow

To convert your Jenkinsfile to GitLab CI/CD:

1. On the top bar, select **Search or go to** and find your project.
1. Open your Jenkinsfile.
1. Above the file, select **Convert to GitLab CI/CD**.
1. Monitor progress by selecting **Automate** > **Sessions**.
1. When the pipeline has successfully executed, on the left sidebar, select **Code** > **Merge requests**.
   A merge request with the title `Duo Workflow: Convert to GitLab CI` is displayed.
1. Review the merge request and make changes as needed.

### Conversion process

The process converts:

- Pipeline stages and steps.
- Environment variables.
- Build triggers and parameters.
- Artifacts and dependencies.
- Parallel execution.
- Conditional logic.
- Post-build actions.

## Example

Jenkinsfile input:

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm build'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        stage('Deploy') {
            when { branch 'main' }
            steps {
                sh './deploy.sh'
            }
        }
    }
}
```

GitLab output:

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - npm install
    - npm build
  artifacts:
    paths:
      - node_modules/
      - dist/

test:
  stage: test
  script:
    - npm test

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - main
```
