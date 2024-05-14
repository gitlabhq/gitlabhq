---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Contribute to the GitLab documentation

The GitLab documentation is the single source of truth (SSOT)
for information about how to configure, use, and troubleshoot GitLab.
Everyone is welcome to contribute to the GitLab documentation.

## Update the documentation

Prerequisites:

- If you're not a GitLab team member, you must update the GitLab documentation from a fork. You can:
  - [Request access to the GitLab community fork](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access).
  - Create your own fork. Go to the [GitLab repository](https://gitlab.com/gitlab-org/gitlab) and in the upper-right corner, select **Fork**.

To update the documentation:

1. Go to the [GitLab community fork](https://gitlab.com/gitlab-community/gitlab) or your own fork.
1. Find the documentation page in the `\doc` directory.
1. In the upper right, select **Edit > Edit single file**.
1. Make your changes.
1. When you're ready to submit your changes, in the **Commit message** text box, enter a commit message.
   Use 3-5 words, start with a capital letter, and do not end with a period.
1. Select **Commit changes**.
1. If you're working from the community fork, a new merge request opens and you can continue to the next step.
   If you're working from your own fork, first do the following:
   1. On the left sidebar, select **Code > Merge requests**.
   1. Select **New merge request**.
   1. For the source branch, select your fork and branch. If you did not create a branch, select `master`.
      For the target branch, select the [GitLab repository](https://gitlab.com/gitlab-org/gitlab) `master` branch.
   1. Select **Compare branches and continue**. A new merge request opens.
1. On the **New merge request** page, select the **Documentation** template and select **Apply template**.
1. In the description, write a brief summary of the changes and link to the related issue, if there is one.
1. Select **Create merge request**.
1. After your merge request is created, look for a message from **GitLab Bot**. This message has instructions for what to do when you're ready for review.

Alternatively, if you don't want to search through the `/doc` directory, on <https://docs.gitlab.com>, at the bottom of any page, select **View page source** or **Edit in Web IDE**.
You are prompted to create a fork or switch to your fork before you can make changes.

When you're developing code, the workflow for updating docs is slightly different.
For details, see the [merge request workflow](../contributing/merge_request_workflow.md).

## What to work on

You don't need an issue to update the documentation, but if you're looking for open issues to work on,
[review the list of documentation issues curated specifically for new contributors](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&label_name%5B%5D=documentation&label_name%5B%5D=docs-only&label_name%5B%5D=Seeking%20community%20contributions&first_page_size=20).

When you find an issue you'd like to work on:

- If the issue is already assigned to someone, pick a different one.
- If the issue is unassigned, add a comment and ask to work on the issue. For a Hackathon, use `@docs-hackathon`. Otherwise, use `@gl-docsteam`. For example:

  ```plaintext
  @docs-hackathon I would like to work on this issue
  ```

You can try installing and running the [Vale linting tool](testing/vale.md)
and fixing the resulting issues.

## Ask for help

Ask for help from the Technical Writing team if you:

- Need help to choose the correct place for documentation.
- Want to discuss a documentation idea or outline.
- Want to request any other help.

To identify someone who can help you:

1. Locate the Technical Writer for the relevant
   [DevOps stage group](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments).
1. Either:
   - If urgent help is required, directly assign the Technical Writer in the issue or in the merge request.
   - If non-urgent help is required, ping the Technical Writer in the issue or merge request.

If you are a member of the GitLab Slack workspace, you can request help in the `#docs` channel.

## Branch naming

The [CI/CD pipeline for the main GitLab project](../pipelines/index.md) is configured to
run shorter, faster pipelines on merge requests that contain only documentation changes.

If you submit documentation-only changes to Omnibus, Charts, or Operator,
to make the shorter pipeline run, you must follow these guidelines when naming your branch:

| Branch name           | Valid example                |
|:----------------------|:-----------------------------|
| Starting with `docs/` | `docs/update-api-issues`     |
| Starting with `docs-` | `docs-update-api-issues`     |
| Ending in `-docs`     | `123-update-api-issues-docs` |

## Backport documentation changes to older branches

Backporting documentation to older branches is something that should be used rarely.
The criteria includes legal issues, emergency security fixes, and fixes to content that
might prevent users from upgrading or cause data loss.

There are two types of backports:

- **Latest stable version:** Maintainers (backend, frontend, docs) can backport
  changes, usually bug fixes but also important documentation changes, into the
  latest stable version.
- **Older stable branches:** To guarantee the
  [maintenance policy](../../policy/maintenance.md) is respected, merging to
  older stable branches is restricted to release managers.

To backport changes to an older branch
[open an issue in the Technical Writing project](https://gitlab.com/gitlab-org/technical-writing/-/issues/new)
using the [backport changes template](https://gitlab.com/gitlab-org/technical-writing/-/blob/main/.gitlab/issue_templates/backport_changes.md),
and follow the steps.
