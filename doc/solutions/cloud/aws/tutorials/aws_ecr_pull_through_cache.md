---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Integrations Solutions Index for GitLab and AWS."
title: 'Tutorial: Configuring AWS ECR Pull Through Cache Rules for Authenticated Access to GitLab.com Projects'
---

1. Open the Amazon ECR console at <https://console.aws.amazon.com/ecr/>.

1. From the navigation bar, choose the Region to configure your private registry settings in.

1. In the navigation pane, choose Private registry, Pull through cache.

1. On the Pull through cache configuration page, choose Add rule.

On Step 1: Specify a source page, for Registry, choose GitLab Container Registry, Next.

On Step 2: Configure authentication page, for Upstream credentials, you must store your authentication credentials for GitLab Container Registry in an AWS Secrets Manager secret. You can specify an existing secret or use the Amazon ECR console to create a new secret.

To use an existing secret, choose Use an existing AWS secret. For Secret name use the drop down to select your existing secret, and then choose Next. For more information on creating a Secrets Manager secret using the Secrets Manager console, see Storing your upstream repository credentials in an AWS Secrets Manager secret.

NOTE:
The AWS Management Console only displays Secrets Manager secrets with names using the ecr-pullthroughcache/ prefix. The secret must also be in the same account and Region that the pull through cache rule is created in.

To create a new secret, choose Create an AWS secret, do the following, then choose Next.

For Secret name, specify a descriptive name for the secret. Secret names must contain 1-512 Unicode characters.

For GitLab Container Registry username, specify your GitLab Container Registry username.

For GitLab Container Registry access token, specify your GitLab Container Registry access token. To follow principles of least privilege, please create a Group Access Token with the Guest role and only the read_registry scope.

On the Step 3: Specify a destination page, for Amazon ECR repository prefix, specify the repository namespace to use when caching images pulled from the source public registry and then choose Next.

By default, a namespace is populated but a custom namespace can be specified as well.

On the Step 4: Review and create page, review the pull through cache rule configuration and then choose Create.

Repeat the previous step for each pull through cache you want to create. The pull through cache rules are created separately for each Region.

To validate that your ECR Pull Through Cache rule was created successfully, you can run the following command via the AWS CLI to validate the rule:

```shell
aws ecr validate-pull-through-cache-rule \
     --ecr-repository-prefix ecr-public \
     --region us-east-2
```

To validate that your ECR Pull Through Cache rule provides pull-through access to the GitLab.com upstream registry, you can to validate by running a `docker pull` command:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/{destination-namespace e.g. gitlab-ef1b}/{path to Gitlab.com project/group where image is hosted}/image_name:tag
```

Example `docker pull` command:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/gitlab-ef1b/guided-explorations/ci-components/working-code-examples/kaniko-component-multiarch-build:latest
```
