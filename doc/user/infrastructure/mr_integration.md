---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Terraform integration in Merge Requests **(FREE)**

Collaborating around Infrastructure as Code (IaC) changes requires both code changes and expected infrastructure changes to be checked and approved. GitLab provides a solution to help collaboration around Terraform code changes and their expected effects using the Merge Request pages. This way users don't have to build custom tools or rely on 3rd party solutions to streamline their IaC workflows.

## Output Terraform Plan information into a merge request

Using the [GitLab Terraform Report artifact](../../ci/yaml/index.md#artifactsreportsterraform),
you can expose details from `terraform plan` runs directly into a merge request widget,
enabling you to see statistics about the resources that Terraform creates,
modifies, or destroys.

## Setup

NOTE:
GitLab ships with a [pre-built CI template](index.md#quick-start) that uses GitLab Managed Terraform state and integrates Terraform changes into merge requests. We recommend customizing the pre-built image and relying on the `gitlab-terraform` helper provided within for a quick setup.

To manually configure a GitLab Terraform Report artifact requires the following steps:

1. For simplicity, let's define a few reusable variables to allow us to
   refer to these files multiple times:

   ```yaml
   variables:
     PLAN: plan.cache
     PLAN_JSON: plan.json
   ```

1. Install `jq`, a
   [lightweight and flexible command-line JSON processor](https://stedolan.github.io/jq/).
1. Create an alias for a specific `jq` command that parses out the information we
   want to extract from the `terraform plan` output:

   ```yaml
   before_script:
     - apk --no-cache add jq
     - alias convert_report="jq -r '([.resource_changes[]?.change.actions?]|flatten)|{\"create\":(map(select(.==\"create\"))|length),\"update\":(map(select(.==\"update\"))|length),\"delete\":(map(select(.==\"delete\"))|length)}'"
   ```

   NOTE:
   In distributions that use Bash (for example, Ubuntu), `alias` statements are not
   expanded in non-interactive mode. If your pipelines fail with the error
   `convert_report: command not found`, alias expansion can be activated explicitly
   by adding a `shopt` command to your script:

   ```yaml
   before_script:
     - shopt -s expand_aliases
     - alias convert_report="jq -r '([.resource_changes[]?.change.actions?]|flatten)|{\"create\":(map(select(.==\"create\"))|length),\"update\":(map(select(.==\"update\"))|length),\"delete\":(map(select(.==\"delete\"))|length)}'"
   ```

1. Define a `script` that runs `terraform plan` and `terraform show`. These commands
   pipe the output and convert the relevant bits into a store variable `PLAN_JSON`.
   This JSON is used to create a
   [GitLab Terraform Report artifact](../../ci/yaml/index.md#artifactsreportsterraform).
   The Terraform report obtains a Terraform `tfplan.json` file. The collected
   Terraform plan report is uploaded to GitLab as an artifact, and is shown in merge requests.

   ```yaml
   plan:
     stage: build
     script:
       - terraform plan -out=$PLAN
       - terraform show --json $PLAN | convert_report > $PLAN_JSON
     artifacts:
       reports:
         terraform: $PLAN_JSON
   ```

   For a full example using the pre-built image, see [Example `.gitlab-ci.yml`
   file](#example-gitlab-ciyml-file).

   For an example displaying multiple reports, see [`.gitlab-ci.yml` multiple reports file](#multiple-terraform-plan-reports).

1. Running the pipeline displays the widget in the merge request, like this:

   ![Merge Request Terraform widget](img/terraform_plan_widget_v13_2.png)

1. Clicking the **View Full Log** button in the widget takes you directly to the
   plan output present in the pipeline logs:

   ![Terraform plan logs](img/terraform_plan_log_v13_0.png)

### Example `.gitlab-ci.yml` file

```yaml
default:
  image: registry.gitlab.com/gitlab-org/terraform-images/stable:latest

  cache:
    key: example-production
    paths:
      - ${TF_ROOT}/.terraform

variables:
  TF_ROOT: ${CI_PROJECT_DIR}/environments/example/production
  TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/example-production

before_script:
  - cd ${TF_ROOT}

stages:
  - prepare
  - validate
  - build
  - deploy

init:
  stage: prepare
  script:
    - gitlab-terraform init

validate:
  stage: validate
  script:
    - gitlab-terraform validate

plan:
  stage: build
  script:
    - gitlab-terraform plan
    - gitlab-terraform plan-json
  artifacts:
    name: plan
    paths:
      - ${TF_ROOT}/plan.cache
    reports:
      terraform: ${TF_ROOT}/plan.json

apply:
  stage: deploy
  environment:
    name: production
  script:
    - gitlab-terraform apply
  dependencies:
    - plan
  when: manual
  only:
    - master
```

### Multiple Terraform Plan reports

Starting with GitLab version 13.2, you can display multiple reports on the Merge Request
page. The reports also display the `artifacts: name:`. See example below for a suggested setup.

```yaml
default:
  image:
    name: registry.gitlab.com/gitlab-org/gitlab-build-images:terraform
    entrypoint:
      - '/usr/bin/env'
      - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

  cache:
    paths:
      - .terraform

stages:
  - build

.terraform-plan-generation:
  stage: build
  variables:
    PLAN: plan.tfplan
    JSON_PLAN_FILE: tfplan.json
  before_script:
    - cd ${TERRAFORM_DIRECTORY}
    - terraform --version
    - terraform init
    - apk --no-cache add jq
  script:
    - terraform validate
    - terraform plan -out=${PLAN}
    - terraform show --json ${PLAN} | jq -r '([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}' > ${JSON_PLAN_FILE}
  artifacts:
    reports:
      terraform: ${TERRAFORM_DIRECTORY}/${JSON_PLAN_FILE}

review_plan:
  extends: .terraform-plan-generation
  variables:
    TERRAFORM_DIRECTORY: "review/"
  # Review will not include an artifact name

staging_plan:
  extends: .terraform-plan-generation
  variables:
    TERRAFORM_DIRECTORY: "staging/"
  artifacts:
    name: Staging

production_plan:
  extends: .terraform-plan-generation
  variables:
    TERRAFORM_DIRECTORY: "production/"
  artifacts:
    name: Production
```
