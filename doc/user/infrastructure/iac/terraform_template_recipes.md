---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform template recipes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Terraform CI/CD templates are deprecated and will be removed in GitLab 18.0.
See [the deprecation announcement](../../../update/deprecations.md#deprecate-terraform-cicd-templates) for more information.

You can customize your Terraform integration by adding the recipes on
this page to your pipeline.

If you'd like to share your own Terraform configuration, consider
[contributing a recipe](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/infrastructure/iac/terraform_template_recipes.md)
to this page.

## Enable a `terraform destroy` job

Add the following snippet to your `.gitlab-ci.yml`:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

destroy:
  extends: .terraform:destroy
```

The `destroy` job is part of the `cleanup` stage. Like the `deploy`
job, the `destroy` job is always `manual` and is not tied to the
default branch.

To connect the `destroy` job to the GitLab environment:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

deploy:
  environment:
    name: $TF_STATE_NAME
    action: start
    on_stop: destroy

destroy:
  extends: .terraform:destroy
  environment:
    name: $TF_STATE_NAME
    action: stop
```

In this configuration, the `destroy` job is always created. However, you might want to create a `destroy` job only if certain
conditions are met.

The following configuration creates a `destroy` job, runs a destroy plan and omits the `deploy` job only if `TF_DESTROY` is true:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

build:
  rules:
    - if: $TF_DESTROY == "true"
      variables:
        TF_CLI_ARGS_plan: "-destroy"
    - when: on_success

deploy:
  environment:
    name: $TF_STATE_NAME
    action: start
    on_stop: destroy
  rules:
    - if: $TF_DESTROY == "true"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $TF_AUTO_DEPLOY == "true"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual

destroy:
  extends: .terraform:destroy
  dependencies:
    - build
  variables:
    TF_CLI_ARGS_destroy: "${TF_PLAN_CACHE}"
  environment:
    name: $TF_STATE_NAME
    action: stop
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $TF_DESTROY == "true"
      when: manual
```

This configuration has a known issue: when the `destroy` job is not in the same pipeline as the `deploy` job, the `on_stop` environment action does not work.

## Run a custom `terraform` command in a job

To define a job that runs a custom `terraform` command, the
`gitlab-terraform` wrapper can be used in any job:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

state-list:
  stage: validate # you can use any stage, just make sure to define it
  script: gitlab-terraform state list
```

The `gitlab-terraform` command sets up a `terraform` command and runs
it with the given arguments.

To run this job in the Terraform state-specific [resource group](../../../ci/resource_groups/_index.md),
assign the job with `resource_group`:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

state-list:
  stage: validate # you can use any stage, just make sure to define it
  resource_group: ${TF_STATE_NAME}
  script: gitlab-terraform state list
```

## Add custom debug tools to jobs

The default image used by Terraform template jobs contains only minimal tooling.
However, you might want to add additional tools for debugging.

To add an additional tool:

1. Install the tool in the `before_script` of a job or pipeline.
1. Use the tool in the `script` or `after_script` block.
   - If you use the `script` block, be sure to re-add the template job commands.

For example, the following snippet installs `bash` and `jq` in the `before_script` for all
jobs in the pipeline:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

default:
  before_script: apk add --update bash jq
```

To add it to only the `build` and `deploy` jobs, add it to those jobs directly:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

build:
  before_script: apk add --update bash jq

deploy:
  before_script: apk add --update bash jq
```

## Add custom container images

For debug tools and simple installations, you should
[add a custom debug tool to your job](#add-custom-debug-tools-to-jobs).
If your tool is complex or benefits from caching,
you can create a custom container image based on the
[`gitlab-terraform`](https://gitlab.com/gitlab-org/terraform-images) images.
You can use your custom image in subsequent Terraform jobs.

To define a custom container image:

1. Define a new `Dockerfile` with custom tooling. For example, install `bash` and `jq` in `.gitlab/ci/Dockerfile`:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

   RUN apk add --update bash jq
   ```

1. In a new job, define a `prepare` stage that builds the image whenever the `Dockerfile` changes.
   - The built image is pushed to the [GitLab container registry](../../packages/container_registry/_index.md). A tag is applied to indicate whether the image was built from a merge request or from the default branch.
1. Use your image in your Terraform jobs, such as `build` and `deploy`.
   - You can combine your image with specialized `before_script` configurations to perform setup commands, like to generate inputs for Terraform.

For example, a fully functioning pipeline configuration might look like:

```yaml
include:
  - template: Terraform.latest.gitlab-ci.yml

variables:
  IMAGE_TAG: latest

workflow:
  rules:
    - if: $CI_MERGE_REQUEST_IID
      changes:
        - .gitlab/ci/Dockerfile
      variables:
        IMAGE_TAG: ${CI_COMMIT_REF_SLUG}
    - when: always

stages:
  - prepare
  - validate
  - test
  - build
  - deploy
  - cleanup

prepare:image:
  needs: []
  stage: prepare
  image:
    name: gcr.io/kaniko-project/executor:v1.9.0-debug
    entrypoint: [""]
  rules:
    # Tag with the commit SHA if we're in an MR
    - if: $CI_MERGE_REQUEST_IID
      changes:
        - .gitlab/ci/Dockerfile
      variables:
        DOCKER_TAG: $CI_COMMIT_REF_SLUG
    # If we're on our main branch, tag with "latest"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - .gitlab/ci/Dockerfile
      variables:
        DOCKER_TAG: latest
  before_script:
    # Authenticate to the docker registry and dependency proxy
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"auth\":\"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
  script:
    - /kaniko/executor
      --context "${CI_PROJECT_DIR}/.gitlab/ci"
      --cache=true
      --dockerfile "${CI_PROJECT_DIR}/.gitlab/ci/Dockerfile"
      --destination "${CI_REGISTRY_IMAGE}:${DOCKER_TAG}"

build:
  image: ${CI_REGISTRY_IMAGE}:${IMAGE_TAG}

deploy:
  image: ${CI_REGISTRY_IMAGE}:${IMAGE_TAG}
```

For an example repository, see the [GitLab Terraform template usage project](https://gitlab.com/gitlab-org/configure/examples/terraform-template-usage).

## Automatically deploy from the default branch

You can automatically deploy from the default branch by setting the `TF_AUTO_DEPLOY` variable
to `"true"`. All other values are interpreted as `"false"`.

```yaml
variables:
  TF_AUTO_DEPLOY: "true"

include:
  - template: Terraform.latest.gitlab-ci.yml
```

## Deploy Terraform to multiple environments

You can run pipelines in multiple environments, each with a unique Terraform state.

```yaml
stages:
  - validate
  - test
  - build
  - deploy

include:
  - template: Terraform/Base.latest.gitlab-ci.yml
  - template: Jobs/SAST-IaC.latest.gitlab-ci.yml

variables:
  # x prevents TF_STATE_NAME from beeing empty for non environment jobs like validate
  # wait for https://gitlab.com/groups/gitlab-org/-/epics/7437 to use variable defaults
  TF_STATE_NAME: x${CI_ENVIRONMENT_NAME}
  TF_CLI_ARGS_plan: "-var-file=vars/${CI_ENVIRONMENT_NAME}.tfvars"

fmt:
  extends: .terraform:fmt
validate:
  extends: .terraform:validate

plan dev:
  extends: .terraform:build
  environment:
    name: dev
plan prod:
  extends: .terraform:build
  environment:
    name: prod

apply dev:
  extends: .terraform:deploy
  environment:
    name: dev

apply prod:
  extends: .terraform:deploy
  environment:
    name: prod
```

This configuration is modified from the [base GitLab template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml).
