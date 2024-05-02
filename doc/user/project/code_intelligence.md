---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use code intelligence to find all uses of an object in your project."
---

# Code intelligence

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Intelligence adds code navigation features common to interactive
development environments (IDE), including:

- Type signatures and symbol documentation.
- Go-to definition.

Code Intelligence is built into GitLab and powered by [LSIF](https://lsif.dev/)
(Language Server Index Format), a file format for precomputed code
intelligence data. GitLab processes one LSIF file per project, and
Code Intelligence does not support different LSIF files per branch.

Follow [epic 4212](https://gitlab.com/groups/gitlab-org/-/epics/4212)
for progress on upcoming code intelligence enhancements.

NOTE:
You can automate this feature in your applications by using [Auto DevOps](../../topics/autodevops/index.md).

## Configure code intelligence

Prerequisites:

- You've checked the LSIF documentation to confirm an
  [LSIF indexer](https://lsif.dev/#implementations-server) exists for your project's languages.

To enable code intelligence for a project:

1. Add a GitLab CI/CD job to your project's `.gitlab-ci.yml`. This job generates the LSIF artifact:

   ```yaml
   code_navigation:
     image: sourcegraph/lsif-go:v1
     allow_failure: true # recommended
     script:
       - lsif-go
     artifacts:
       reports:
         lsif: dump.lsif
   ```

1. Depending on your CI/CD configuration, you might need to run the job manually,
   or wait for it to run as part of an existing pipeline.

This file is limited to 100 MB by the
[(`ci_max_artifact_size_lsif`)](../../administration/instance_limits.md#maximum-file-size-per-type-of-artifact)
artifact application limit. On self-managed installations, an instance administrator
can configure this value.

## View code intelligence results

After the job succeeds, browse your repository to see code intelligence information:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Go to the file in your repository. If you know the filename, either:
   - Enter the `/~` keyboard shortcut to open the file finder, and enter the file's name.
   - In the upper right, select **Find file**.
1. Point to lines of code. Items on that line with information from code intelligence display a dotted line underneath them:

   ![Code intelligence](img/code_intelligence_v17_0.png)

1. Select the item to learn more information about it.

## Find references

Use code intelligence to see all uses of an object:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Go to the file in your repository. If you know the filename, either:
   - Enter the `/~` keyboard shortcut to open the file finder, and enter the file's name.
   - In the upper right, select **Find file**.
1. Point to the object, then select it.
1. In the dialog, select **References** to view a list of the
   files that use this object.
