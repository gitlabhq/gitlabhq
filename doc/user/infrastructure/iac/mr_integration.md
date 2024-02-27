---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Terraform integration in merge requests

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Collaborating around Infrastructure as Code (IaC) changes requires both code changes and expected infrastructure changes to be checked and approved. GitLab provides a solution to help collaboration around Terraform code changes and their expected effects using the merge request pages. This way users don't have to build custom tools or rely on 3rd party solutions to streamline their IaC workflows.

## Output Terraform Plan information into a merge request

Using the [GitLab Terraform Report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsterraform),
you can expose details from `terraform plan` runs directly into a merge request widget,
enabling you to see statistics about the resources that Terraform creates,
modifies, or destroys.

WARNING:
Like any other job artifact, Terraform plan data is viewable by anyone with the Guest role on the repository.
Neither Terraform nor GitLab encrypts the plan file by default. If your Terraform `plan.json` or `plan.cache`
files include sensitive data like passwords, access tokens, or certificates, you should
encrypt the plan output or modify the project visibility settings. You should also **disable**
[public pipelines](../../../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects)
and set the [artifact's public flag to false](../../../ci/yaml/index.md#artifactspublic) (`public: false`).
This setting ensures artifacts are accessible only to GitLab administrators and project members with at least the Reporter role.

## Configure Terraform report artifacts

GitLab [integrates with Terraform](index.md#integrate-your-project-with-terraform) and [OpenTofu](index.md#integrate-your-project-with-opentofu)
through CI/CD templates and components that use GitLab-managed Terraform state and display Terraform changes on merge requests.

### Automatically configure Terraform report artifacts

You should use either the [Terraform CI/CD templates](index.md#integrate-your-project-with-terraform)
or the [OpenTofu CI/CD component](https://gitlab.com/components/opentofu), which automatically configure the Terraform report artifacts
in the `plan` jobs.

### Manually configure Terraform report artifacts

For a quick setup, you should customize the pre-built image and rely on the `gitlab-terraform` and `gitlab-tofu` helpers.

To manually configure a GitLab Terraform Report artifact:

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
   [GitLab Terraform Report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsterraform).
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

1. Running the pipeline displays the widget in the merge request, like this:

   ![merge request Terraform widget](img/terraform_plan_widget_v13_2.png)

1. Selecting the **View Full Log** button in the widget takes you directly to the
   plan output present in the pipeline logs:

   ![Terraform plan logs](img/terraform_plan_log_v13_0.png)
