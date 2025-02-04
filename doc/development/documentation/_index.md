---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Contribute to the GitLab documentation
---

The GitLab documentation is the single source of truth (SSoT)
for information about how to configure, use, and troubleshoot GitLab.
Everyone is welcome to contribute to the GitLab documentation.

The following instructions are for community contributors.

## Update the documentation

Prerequisites:

- [Request access to the GitLab community fork](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access).
  The community fork is a shared copy of the main GitLab repository.
 When you make the request, you'll be asked to answer a few questions. Let them know
 that you're interested in contributing to the GitLab documentation.

To update the documentation:

1. Go to the GitLab community fork [`/doc` directory](https://gitlab.com/gitlab-community/gitlab/-/tree/master/doc).
1. Find the documentation page you want to update. If you're not sure where the page is,
   look at the URL of the page on <https://docs.gitlab.com>.
   The path is listed there.
1. In the upper right, select **Edit > Edit single file**.
1. Make your updates.
1. When you're done, in the **Commit message** text box, enter a commit message.
   Use 3-5 words, start the first word with a capital letter, and do not end the phrase with a period.
1. Select **Commit changes**.
1. A new merge request opens.
1. On the **New merge request** page, select the **Documentation** template and select **Apply template**.
1. In the description, write a brief summary of the changes and link to the related issue, if there is one.
1. Select **Create merge request**.

After your merge request is created, look for a message from **GitLab Bot**. This message has instructions for what to do when you're ready for review.

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

## Edit a document from your own fork

If you already have your own fork of the GitLab repository, you can use it,
rather than using the GitLab community fork.

1. On <https://docs.gitlab.com>, scroll to the bottom of the page you want to edit.
1. Select **View page source**.
1. In the upper-right corner, select **Edit > Edit single file**.
1. Make your updates.
1. When you're done, in the **Commit message** text box, enter a commit message.
   Use 3-5 words, start the first word with a capital letter, and do not end the phrase with a period.
1. Select **Commit changes**.
1. Note the name of your branch and then select **Commit changes**.

The changes were added to GitLab in your forked repository, in a branch with the name noted in the last step.

Now, create a merge request. This merge request is how the changes from your branch
will be merged into the GitLab `master` branch.

1. On the left sidebar, select **Code > Merge requests**.
1. Select **New merge request**.
1. For the source branch, select your fork and branch.
1. For the target branch, select the [GitLab repository](https://gitlab.com/gitlab-org/gitlab) `master` branch.
1. Select **Compare branches and continue**. A new merge request opens.
1. On the **New merge request** page, select the **Documentation** template and select **Apply template**.
1. In the description, write a brief summary of the changes and link to the related issue, if there is one.
1. Select **Create merge request**.

After your merge request is created, look for a message from **GitLab Bot**. This message has instructions for what to do when you're ready for review.
