---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Migrate container images from Amazon ECR to GitLab'
---

Migrating container images between registries can be time-consuming when done manually. This tutorial describes how to set up a CI/CD pipeline to automate the bulk migration of container images from Amazon Elastic Container Registry (ECR) to the GitLab container registry.

To migrate container images from ECR:

1. [Configure AWS permissions](#configure-aws-permissions)
1. [Add AWS credentials as variables in the UI](#add-aws-credentials-as-variables-in-the-ui)
1. [Create the migration pipeline](#create-the-migration-pipeline)
1. [Run and verify the migration](#run-and-verify-the-migration)

When you put it all together, your `.gitlab-ci.yml` should look similar to the [sample configuration](#example-gitlab-ciyml-configuration) provided at the end of this tutorial.

## Before you begin

You must have:

- Maintainer role or higher in your GitLab project
- Access to your AWS account with permissions to create IAM users
- Your AWS account ID
- Your AWS region where ECR repositories are located
- Sufficient storage space in your GitLab container registry

## Configure AWS permissions

In AWS IAM, create a new policy and user with read-only access to ECR:

1. In the AWS Management Console, go to IAM.
1. Create a new policy:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ecr:GetAuthorizationToken",
                   "ecr:BatchCheckLayerAvailability",
                   "ecr:GetDownloadUrlForLayer",
                   "ecr:DescribeRepositories",
                   "ecr:ListImages",
                   "ecr:DescribeImages",
                   "ecr:BatchGetImage"
               ],
               "Resource": "*"
           }
       ]
   }
   ```

1. Create a new IAM user and attach the policy.
1. Generate and save access keys for the IAM user.

## Add AWS credentials as variables in the UI

Configure the required AWS credentials as variables in your GitLab project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and add:
   - `AWS_ACCOUNT_ID`: Your AWS account number.
   - `AWS_DEFAULT_REGION`: Your ECR region. For example, `us-east-1`.
   - `AWS_ACCESS_KEY_ID`: The access key ID from your IAM user.
     - Select **Mask variable**.
   - `AWS_SECRET_ACCESS_KEY`: The secret access key from your IAM user.
     - Select **Mask variable**.

## Create the migration pipeline

Create a new `.gitlab-ci.yml` file in your repository with the following configurations:

### Set image and service

Use Docker-in-Docker to handle container operations:

```yaml
image: docker:20.10
services:
  - docker:20.10-dind
```

### Define pipeline variables

Set up the required variables for the pipeline:

```yaml
variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  BULK_MIGRATE: "true"
```

### Configure the migration job

Create the migration job that handles the transfer:

```yaml
migration:
  stage: deploy
  script:
    # Install required tools
    - apk add --no-cache aws-cli jq

    # Verify AWS credentials
    - aws sts get-caller-identity

    # Log in to registries
    - aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    - docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

    # Get list of ECR repositories
    - REPOS=$(aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text)

    # Process each repository
    - |
      for repo in $REPOS; do
        echo "Processing repository: $repo"

        # Get all tags for this repository
        TAGS=$(aws ecr describe-images --repository-name $repo --query 'imageDetails[*].imageTags[]' --output text)

        # Process each tag
        for tag in $TAGS; do
          echo "Processing tag: $tag"

          # Pull image from ECR
          docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag}

          # Tag for GitLab registry
          docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag} ${CI_REGISTRY_IMAGE}/${repo}:${tag}

          # Push to GitLab
          docker push ${CI_REGISTRY_IMAGE}/${repo}:${tag}
        done
      done
```

## Run and verify the migration

After setting up the pipeline:

1. Commit and push the `.gitlab-ci.yml` file to your repository.
1. Go to **CI/CD > Pipelines** to monitor the migration progress.
1. After completion, verify the migration:
   - Go to **Packages and registries > Container Registry**.
   - Verify all repositories and tags are present.
   - Test pulling some migrated images.

## Example `.gitlab-ci.yml` configuration

When you follow all the steps mentioned above, your complete `.gitlab-ci.yml` should look similar to this:

```yaml
image: docker:20.10
services:
  - docker:20.10-dind

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  BULK_MIGRATE: "true"

migration:
  stage: deploy
  script:
    # Install required tools
    - apk add --no-cache aws-cli jq

    # Verify AWS credentials
    - aws sts get-caller-identity

    # Log in to registries
    - aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    - docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

    # Get list of ECR repositories
    - REPOS=$(aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text)

    # Process each repository
    - |
      for repo in $REPOS; do
        echo "Processing repository: $repo"

        # Get all tags for this repository
        TAGS=$(aws ecr describe-images --repository-name $repo --query 'imageDetails[*].imageTags[]' --output text)

        # Process each tag
        for tag in $TAGS; do
          echo "Processing tag: $tag"

          # Pull image from ECR
          docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag}

          # Tag for GitLab registry
          docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag} ${CI_REGISTRY_IMAGE}/${repo}:${tag}

          # Push to GitLab
          docker push ${CI_REGISTRY_IMAGE}/${repo}:${tag}
        done
      done
  rules:
    - if: $BULK_MIGRATE == "true"
```
