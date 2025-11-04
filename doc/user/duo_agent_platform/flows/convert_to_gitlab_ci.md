---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert to GitLab CI/CD Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../policy/development_stages_support.md) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci`. Disabled by default, but can be enabled for the instance or a user.
- The `duo_workflow` flag must also be enabled, but it is enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Convert to GitLab CI/CD Flow helps you migrate your Jenkins pipelines to GitLab CI/CD. This flow:

- Analyzes your existing Jenkins pipeline configuration.
- Converts Jenkins pipeline syntax to GitLab CI/CD YAML.
- Suggests best practices for GitLab CI/CD implementation.
- Creates a merge request with the converted pipeline configuration.
- Provides guidance on migrating Jenkins plugins to GitLab features.

This flow is available in the GitLab UI only.

## Prerequisites

To convert a Jenkinsfile, you must:

- Have access to your Jenkins pipeline configuration.
- Have at least the Developer role in the target GitLab project.
- Meet [the other prerequisites](../../duo_agent_platform/_index.md#prerequisites).

## Use the flow

To convert your Jenkinsfile to GitLab CI/CD:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
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
