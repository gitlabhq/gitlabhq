---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Contribute to the GitLab documentation

Everyone is welcome to update the GitLab documentation!

## Work without an issue

You don't need an issue to update the documentation.

On [https://docs.gitlab.com](https://docs.gitlab.com), at the bottom of any page,
you can select **View page source** or **Edit in Web IDE** and [get started with a merge request](#open-your-merge-request).

You can alternately:

- Choose a page [in the `/doc` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)
  and edit it from there.
- Try installing and running the [Vale linting tool](testing.md#vale)
  and fixing the resulting issues.

When you're developing code, the workflow for updating docs is slightly different.
For details, see the [merge request workflow](../contributing/merge_request_workflow.md).

## Search available issues

If you're looking for an open issue, you can
[review the list of documentation issues curated specifically for new contributors](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&label_name%5B%5D=documentation&label_name%5B%5D=docs-only&label_name%5B%5D=Seeking%20community%20contributions&first_page_size=20).

When you find an issue you'd like to work on:

- If the issue is already assigned to someone, pick a different one.
- If the issue is unassigned, add a comment and ask to work on the issue. For a Hackathon, use `@docs-hackathon`. Otherwise, use `@gl-docsteam`. For example:

  ```plaintext
  @docs-hackathon I would like to work on this issue
  ```

- Do not ask for more than three issues at a time.

## Open your merge request

When you are ready to update the documentation:

1. Go to the [GitLab repository](https://gitlab.com/gitlab-org/gitlab).
1. In the upper-right corner, select **Fork**. Forking makes a copy of the repository on GitLab.com.
1. In your fork, find the documentation page in the `\doc` directory.
1. If you know Git, make your changes and open a merge request.
   If not, follow these steps:
   1. In the upper-right corner, select **Edit** if it is visible.
      If it is not, select the down arrow (**{chevron-lg-down}**) next to
      **Open in Web IDE** or **Gitpod**, and select **Edit**.
   1. In the **Commit message** text box, enter a commit message.
      Use 3-5 words, start with a capital letter, and do not end with a period.
   1. Select **Commit changes**.
   1. On the left sidebar, select **Merge requests**.
   1. Select **New merge request**.
   1. For the source branch, select your fork and branch. If you did not create a branch, select `master`.
      For the target branch, select the [GitLab repository](https://gitlab.com/gitlab-org/gitlab) `master` branch.
   1. Select **Compare branches and continue**. A new merge request opens.
   1. Select the **Documentation** template. In the description, write a brief summary of the changes and link to the related issue, if there is one.
   1. Select **Create merge request**.

## Ask for help

Ask for help from the Technical Writing team if you:

- Need help to choose the correct place for documentation.
- Want to discuss a documentation idea or outline.
- Want to request any other help.

To identify someone who can help you:

1. Locate the Technical Writer for the relevant
   [DevOps stage group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).
1. Either:
   - If urgent help is required, directly assign the Technical Writer in the issue or in the merge request.
   - If non-urgent help is required, ping the Technical Writer in the issue or merge request.

If you are a member of the GitLab Slack workspace, you can request help in the `#docs` channel.
