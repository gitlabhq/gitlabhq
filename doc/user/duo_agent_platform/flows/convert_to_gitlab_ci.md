---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert to GitLab CI/CD flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../policy/development_stages_support.md) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `duo_workflow_in_ci`. Disabled by default. The `duo_workflow` flag must also be enabled.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The **Convert to GitLab CI/CD** flow helps you migrate your Jenkins pipelines to GitLab CI/CD. This flow:

- Analyzes your existing Jenkins pipeline configuration.
- Converts Jenkins pipeline syntax to GitLab CI/CD YAML.
- Suggests best practices for GitLab CI/CD implementation.
- Creates a merge request with the converted pipeline configuration.
- Provides guidance on migrating Jenkins plugins to GitLab features.

This flow is available in the GitLab UI only.

## Prerequisites

Before you can convert a Jenkinsfile, you must have:

- Access to your Jenkins pipeline configuration.
- At least Developer role in the target GitLab project.
- GitLab Duo [turned on for your group or project](../../gitlab_duo/turn_on_off.md).
- Feature flags [`duo_workflow` and `duo_workflow_in_ci` enabled](../../../administration/feature_flags/_index.md).

## Use the flow

To convert your Jenkinsfile to GitLab CI/CD:

1. On the left sidebar, select **Search or go to** and find your project.
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
