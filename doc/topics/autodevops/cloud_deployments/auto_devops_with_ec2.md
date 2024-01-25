---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Use Auto DevOps to deploy to EC2

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216008) in GitLab 13.6.

To use [Auto DevOps](../index.md) to deploy to EC2:

1. Define [your AWS credentials as CI/CD variables](../../../ci/cloud_deployment/index.md#authenticate-gitlab-with-aws).
1. In your `.gitlab-ci.yml` file, reference the `Auto-Devops.gitlab-ci.yml` template.
1. Define a job for the `build` stage named `build_artifact`. For example:

   ```yaml
   # .gitlab-ci.yml

   include:
     - template: Auto-DevOps.gitlab-ci.yml

   variables:
     AUTO_DEVOPS_PLATFORM_TARGET: EC2

   build_artifact:
     stage: build
     script:
       - <your build script goes here>
     artifacts:
       paths:
         - <built artifact>
   ```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video walkthrough of this process, view [Auto Deploy to EC2](https://www.youtube.com/watch?v=4B-qSwKnacA).
