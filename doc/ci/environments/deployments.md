---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deployments
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When you deploy a version of your code to an environment, you create a deployment.
There is usually only one active deployment per environment.

GitLab:

- Provides a full history of deployments to each environment.
- Tracks your deployments, so you always know what is deployed on your
  servers.

If you have a deployment service like [Kubernetes](../../user/infrastructure/clusters/_index.md)
associated with your project, you can use it to assist with your deployments.

After a deployment is created, you can roll it out to users.

## Configure manual deployments

You can create a job that requires someone to manually start the deployment.
For example:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

The `when: manual` action:

- Exposes the **Run** (**{play}**) button for the job in the GitLab UI, with the text **Can be manually deployed to &lt;environment&gt;**.
- Means the `deploy_prod` job must be triggered manually.

You can find **Run** (**{play}**) in the pipelines, environments, deployments, and jobs views.

## Track newly included merge requests per deployment

GitLab can track newly included merge requests per deployment.
When a deployment succeeds, the system calculates commit-diffs between the latest deployment and the previous deployment.
You can fetch tracking information with the [Deployment API](../../api/deployments.md#list-of-merge-requests-associated-with-a-deployment)
or view it at a post-merge pipeline in [merge request pages](../../user/project/merge_requests/_index.md).

To enable tracking configure your environment so either:

- The [environment name](../yaml/_index.md#environmentname) doesn't use folders with `/` (long-lived or top-level environments).
- The [environment tier](_index.md#deployment-tier-of-environments) is either `production` or `staging`.

  Here are some example configurations using the [`environment` keyword](../yaml/_index.md#environment) in `.gitlab-ci.yml`:

  ```yaml
  # Trackable
  environment: production
  environment: production/aws
  environment: development

  # Non Trackable
  environment: review/$CI_COMMIT_REF_SLUG
  environment: testing/aws
  ```

Configuration changes apply only to new deployments. Existing deployment records do not have merge requests linked or unlinked from them.

## Check out deployments locally

A reference in the Git repository is saved for each deployment, so
knowing the state of your current environments is only a `git fetch` away.

In your Git configuration, append the `[remote "<your-remote>"]` block with an extra
fetch line:

```plaintext
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## Archive old deployments

When a new deployment happens in your project,
GitLab creates [a special Git-ref to the deployment](#check-out-deployments-locally).
Since these Git-refs are populated from the remote GitLab repository,
you could find that some Git operations, such as `git-fetch` and `git-pull`,
become slower as the number of deployments in your project increases.

To maintain the efficiency of your Git operations, GitLab keeps
only recent deployment refs (up to 50,000) and deletes the rest of the old deployment refs.
Archived deployments are still available, in the UI or by using the API, for auditing purposes.
Also, you can still fetch the deployed commit from the repository
with specifying the commit SHA (for example, `git checkout <deployment-sha>`), even after archive.

NOTE:
GitLab preserves all commits as [`keep-around` refs](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)
so that deployed commits are not garbage collected, even if it's not referenced by the deployment refs.

## Deployment rollback

When you roll back a deployment on a specific commit,
a _new_ deployment is created. This deployment has its own unique job ID.
It points to the commit you're rolling back to.

For the rollback to succeed, the deployment process must be defined in
the job's `script`.

Only the [deployment jobs](../jobs/_index.md#deployment-jobs) are run.
In cases where a previous job generates artifacts that must be regenerated
on deploy, you must manually run the necessary jobs from the pipelines page.
For example, if you use Terraform and your `plan` and `apply` commands are separated
into multiple jobs, you must manually run the jobs to deploy or roll back.

### Retry or roll back a deployment

If there is a problem with a deployment, you can retry it or roll it back.

To retry or roll back a deployment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Environments**.
1. Select the environment.
1. To the right of the deployment name:
   - To retry a deployment, select **Re-deploy to environment**.
   - To roll back to a deployment, next to a previously successful deployment, select **Rollback environment**.

NOTE:
If you have [prevented outdated deployment jobs](deployment_safety.md#prevent-outdated-deployment-jobs) in your project,
the rollback buttons might be hidden or disabled.
In this case, see [job retries for rollback deployments](deployment_safety.md#job-retries-for-rollback-deployments).

## Related topics

- [Environments](_index.md)
- [Downstream pipelines for deployments](../pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments)
- [Deploy to multiple environments with GitLab CI/CD (blog post)](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/)
- [Review apps](../review_apps/_index.md)
- [Track deployments of an external deployment tool](external_deployment_tools.md)

## Troubleshooting

When you work with deployments, you might encounter the following issues.

### Deployment refs are not found

GitLab [deletes old deployment refs](#archive-old-deployments)
to keep your Git repository performant.

If you have to restore archived Git-refs on GitLab Self-Managed, ask an administrator
to execute the following command on Rails console:

```ruby
Project.find_by_full_path(<your-project-full-path>).deployments.where(archived: true).each(&:create_ref)
```

GitLab might drop this support in the future for the performance concern.
You can open an issue in [GitLab Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues/new)
to discuss the behavior of this feature.
