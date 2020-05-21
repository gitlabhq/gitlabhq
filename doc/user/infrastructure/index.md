---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Infrastructure as code with Terraform and GitLab

## GitLab managed Terraform State

[Terraform remote backends](https://www.terraform.io/docs/backends/index.html)
enable you to store the state file in a remote, shared store. GitLab uses the
[Terraform HTTP backend](https://www.terraform.io/docs/backends/types/http.html)
to securely store the state files in local storage (the default) or
[the remote store of your choice](../../administration/terraform_state.md).

The GitLab managed Terraform state backend can store your Terraform state easily and
securely, and spares you from setting up additional remote resources like
Amazon S3 or Google Cloud Storage. Its features include:

- Supporting encryption of the state file both in transit and at rest.
- Locking and unlocking state.
- Remote Terraform plan and apply execution.

To get started, there are two different options when using GitLab managed Terraform State.

- Use a local machine
- Use GitLab CI

## Get Started using local development

If you are planning to only run `terraform plan` and `terraform apply` commands from your local machine, this is a simple way to get started.

First, create your project on your GitLab instance.

Next, define the Terraform backend in your Terraform project to be:

```hcl
terraform {
  backend "http" {
  }
}
```

Finally, you need to run `terraform init` on your local machine and pass in the following options. The below example is using GitLab.com:

```shell
terraform init \
    -backend-config="address=https://gitlab.com/api/v4/projects/<YOUR-PROJECT-ID>/terraform/state/<YOUR-PROJECT-NAME>" \
    -backend-config="lock_address=https://gitlab.com/api/v4/projects/<YOUR-PROJECT-ID>/terraform/state/<YOUR-PROJECT-NAME>/lock" \
    -backend-config="unlock_address=https://gitlab.com/api/v4/projects/<YOUR-PROJECT-ID>/terraform/state/<YOUR-PROJECT-NAME>/lock" \
    -backend-config="username=<YOUR-USERNAME>" \
    -backend-config="password=<YOUR-ACCESS-TOKEN>" \
    -backend-config="lock_method=POST" \
    -backend-config="unlock_method=DELETE" \
    -backend-config="retry_wait_min=5"
```

This will initialize your Terraform state and store that state within your GitLab project.

NOTE: YOUR-PROJECT-ID and YOUR-PROJECT-NAME can be accessed from the project main page.

## Get Started using a GitLab CI

Another route is to leverage GitLab CI to run your `terraform plan` and `terraform apply` commands.

### Configure the CI variables

To use the Terraform backend, [first create a Personal Access Token](../profile/personal_access_tokens.md) with the `api` scope. Keep in mind that the Terraform backend is restricted to tokens with [Maintainer access](../permissions.md) to the repository.

To keep the Personal Access Token secure, add it as a [CI/CD environment variable](../../ci/variables/README.md). In this example we set ours to the ENV: `GITLAB_TF_PASSWORD`.

If you are planning to use the ENV on a branch which is not protected, make sure to set the variable protection settings correctly.

### Configure the Terraform backend

Next we need to define the [http backend](https://www.terraform.io/docs/backends/types/http.html). In your Terraform project add the following code block in a `.tf` file such as `backend.tf` or wherever you desire to define the remote backend:

```hcl
terraform {
  backend "http" {
  }
}
```

### Configure the CI YAML file

Finally, configure a `.gitlab-ci.yaml`, which lives in the root of your project repository.

In our case we are using a pre-built image:

```yaml
image:
  name: hashicorp/terraform:light
  entrypoint:
    - '/usr/bin/env'
    - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
```

We then define some environment variables to make life easier. `GITLAB_TF_ADDRESS` is the URL of the GitLab instance where this pipeline runs, and `TF_ROOT` is the directory where the Terraform commands must be executed.

```yaml
variables:
  GITLAB_TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${CI_PROJECT_NAME}
  TF_ROOT: ${CI_PROJECT_DIR}/environments/cloudflare/production

cache:
  paths:
    - .terraform
```

In a `before_script`, pass a `terraform init` call containing configuration parameters.
These parameters correspond to variables required by the
[http backend](https://www.terraform.io/docs/backends/types/http.html):

```yaml
before_script:
  - cd ${TF_ROOT}
  - terraform --version
  - terraform init -backend-config="address=${GITLAB_TF_ADDRESS}" -backend-config="lock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="unlock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="username=${GITLAB_USER_LOGIN}" -backend-config="password=${GITLAB_TF_PASSWORD}" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"

stages:
  - validate
  - build
  - test
  - deploy

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: build
  script:
    - terraform plan
    - terraform show

apply:
  stage: deploy
  environment:
    name: production
  script:
    - terraform apply
  dependencies:
    - plan
  when: manual
  only:
    - master
```

### Push to GitLab

Pushing your project to GitLab triggers a CI job pipeline, which runs the `terraform init`, `terraform validate`, and `terraform plan` commands automatically.

The output from the above `terraform` commands should be viewable in the job logs.

## Example project

See [this reference project](https://gitlab.com/nicholasklick/gitlab-terraform-aws) using GitLab and Terraform to deploy a basic AWS EC2 within a custom VPC.

## Output Terraform Plan information into a merge request

Using the [GitLab Terraform Report Artifact](../../ci/pipelines/job_artifacts.md#artifactsreportsterraform),
you can expose details from `terraform plan` runs directly into a merge request widget,
enabling you to see statistics about the resources that Terraform will create,
modify, or destroy.

Let's explore how to configure a GitLab Terraform Report Artifact:

1. First, for simplicity, let's define a few reusable variables to allow us to
   refer to these files multiple times:

   ```yaml
   variables:
     PLAN: plan.tfplan
     PLAN_JSON: tfplan.json
   ```

1. Next we need to install `jq`, a [lightweight and flexible command-line JSON processor](https://stedolan.github.io/jq/). We will also create an alias for a specific `jq` command that parses out the extact information we want to extract from the `terraform plan` output:

```yaml
before_script:
  - apk --no-cache add jq
  - alias convert_report="jq -r '([.resource_changes[]?.change.actions?]|flatten)|{\"create\":(map(select(.==\"create\"))|length),\"update\":(map(select(.==\"update\"))|length),\"delete\":(map(select(.==\"delete\"))|length)}'"
```

1. Finally, we define a `script` that runs `terraform plan` and also a `terraform show` which pipes the output and converts the relevant bits into a store variable `PLAN_JSON`. This json is then leveraged to create a [GitLab Terraform Report Artifact](../../ci/pipelines/job_artifacts.md#artifactsreportsterraform).

The terraform report obtains a Terraform tfplan.json file. The collected Terraform plan report will be uploaded to GitLab as an artifact and will be automatically shown in merge requests.

```yaml
plan:
  stage: build
  script:
    - terraform plan -out=$PLAN
    - terraform show --json $PLAN | convert_report > $PLAN_JSON
  artifacts:
    name: plan
    paths:
      - $PLAN
    reports:
      terraform: $PLAN_JSON
```

A full `.gitlab-ci.yaml` file could look like this:

```yaml
image:
  name: hashicorp/terraform:light
  entrypoint:
    - '/usr/bin/env'
    - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# Default output file for Terraform plan
variables:
  GITLAB_TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${CI_PROJECT_NAME}
  PLAN: plan.tfplan
  PLAN_JSON: tfplan.json
  TF_ROOT: ${CI_PROJECT_DIR}

cache:
  paths:
    - .terraform

before_script:
  - apk --no-cache add jq
  - alias convert_report="jq -r '([.resource_changes[]?.change.actions?]|flatten)|{\"create\":(map(select(.==\"create\"))|length),\"update\":(map(select(.==\"update\"))|length),\"delete\":(map(select(.==\"delete\"))|length)}'"
  - cd ${TF_ROOT}
  - terraform --version
  - terraform init -backend-config="address=${GITLAB_TF_ADDRESS}" -backend-config="lock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="unlock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="username=${GITLAB_USER_LOGIN}" -backend-config="password=${GITLAB_TF_PASSWORD}" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"

stages:
  - validate
  - build
  - deploy

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: build
  script:
    - terraform plan -out=$PLAN
    - terraform show --json $PLAN | convert_report > $PLAN_JSON
  artifacts:
    name: plan
    paths:
      - ${TF_ROOT}/plan.tfplan
    reports:
      terraform: ${TF_ROOT}/tfplan.json

# Separate apply job for manual launching Terraform as it can be destructive
# action.
apply:
  stage: deploy
  environment:
    name: production
  script:
    - terraform apply -input=false $PLAN
  dependencies:
    - plan
  when: manual
  only:
    - master

```

1. Running the pipeline displays the widget in the merge request, like this:

   ![MR Terraform widget](img/terraform_plan_widget_v13_0.png)

1. Clicking the **View Full Log** button in the widget takes you directly to the
   plan output present in the pipeline logs:

   ![Terraform plan logs](img/terraform_plan_log_v13_0.png)

### Example `.gitlab-ci.yaml` file

```yaml
image:
  name: hashicorp/terraform:light
  entrypoint:
    - '/usr/bin/env'
    - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# Default output file for Terraform plan
variables:
  GITLAB_TF_ADDRESS: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${CI_PROJECT_NAME}
  PLAN: plan.tfplan
  PLAN_JSON: tfplan.json
  TF_ROOT: ${CI_PROJECT_DIR}

cache:
  paths:
    - .terraform

before_script:
  - apk --no-cache add jq
  - alias convert_report="jq -r '([.resource_changes[]?.change.actions?]|flatten)|{\"create\":(map(select(.==\"create\"))|length),\"update\":(map(select(.==\"update\"))|length),\"delete\":(map(select(.==\"delete\"))|length)}'"
  - cd ${TF_ROOT}
  - terraform --version
  - terraform init -backend-config="address=${GITLAB_TF_ADDRESS}" -backend-config="lock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="unlock_address=${GITLAB_TF_ADDRESS}/lock" -backend-config="username=${GITLAB_USER_LOGIN}" -backend-config="password=${GITLAB_TF_PASSWORD}" -backend-config="lock_method=POST" -backend-config="unlock_method=DELETE" -backend-config="retry_wait_min=5"

stages:
  - validate
  - build
  - deploy

validate:
  stage: validate
  script:
    - terraform validate

plan:
  stage: build
  script:
    - terraform plan -out=$PLAN
    - terraform show --json $PLAN | convert_report > $PLAN_JSON
  artifacts:
    name: plan
    paths:
      - ${TF_ROOT}/plan.tfplan
    reports:
      terraform: ${TF_ROOT}/tfplan.json

# Separate apply job for manual launching Terraform as it can be destructive
# action.
apply:
  stage: deploy
  environment:
    name: production
  script:
    - terraform apply -input=false $PLAN
  dependencies:
    - plan
  when: manual
  only:
    - master

```
