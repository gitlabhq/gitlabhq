---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tags **(FREE)**

In Git, a tag marks an important point in a repository's history.
Git supports two types of tags:

- **Lightweight tags** point to specific commits, and contain no other information.
  Also known as soft tags. Create or remove them as needed.
- **Annotated tags** contain metadata, can be signed for verification purposes,
  and can't be changed.

The creation or deletion of a tag can be used as a trigger for automation, including:

- Using a [webhook](../../integrations/webhook_events.md#tag-events) to automate actions
  like Slack notifications.
- Signaling a [repository mirror](../mirror/index.md) to update.
- Running a CI/CD pipeline with [`if: $CI_COMMIT_TAG`](../../../../ci/jobs/job_control.md#common-if-clauses-for-rules).

When you [create a release](../../releases/index.md),
GitLab also creates a tag to mark the release point.
Many projects combine an annotated release tag with a stable branch. Consider
setting deployment or release tags automatically.

To prevent users from removing a tag with `git push`, create a [push rule](../push_rules.md).

## Create a tag

Tags can be created from the command line, or the GitLab UI.

### From the command line

To create either a lightweight or annotated tag from the command line, and push it upstream:

1. To create a lightweight tag, run the command `git tag TAG_NAME`, changing
   `TAG_NAME` to your desired tag name.
1. To create an annotated tag, run one of the versions of `git tag` from the command line:

   ```shell
   # In this short version, the annotated tag's name is "v1.0",
   # and the message is "Version 1.0".
   git tag -a v1.0 -m "Version 1.0"

   # Use this version to write a longer tag message
   # for annotated tag "v1.0" in your text editor.
   git tag -a v1.0
   ```

1. Push your tags upstream with `git push origin --tags`.

### From the UI

To create a tag from the GitLab UI:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Tags**.
1. Select **New tag**.
1. Provide a **Tag name**.
1. For **Create from**, select an existing branch name, tag, or commit SHA.
1. Optional. Add a **Message** to create an annotated tag, or leave blank to
   create a lightweight tag.
1. Select **Create tag**.

## View tags for a project

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Tags**.

![Example of a single tag](img/tag-display_v15_9.png)

In the GitLab UI, each tag displays:

- The tag name. (**{tag}**)
- Optional. If the tag is [protected](../../protected_tags.md), a **protected** badge.
- The commit SHA (**{commit}**), linked to the commit's contents.
- The commit's title and creation date.
- Optional. A link to the release (**{rocket}**).
- Optional. If a pipeline has been run, the current pipeline status.
- Download links to the source code and artifacts linked to the tag.
- A [**Create release**](../../releases/index.md#create-a-release) (**{pencil}**) link.
- A link to delete the tag.

## Find tags containing a commit

To search all Git tags for a particular SHA (commit identifier), run this
command from the command line, replacing `SHA` with the SHA of the commit:

```shell
git tag --contains SHA
```

## Related topics

- [Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging) Git reference page.
- [Protected tags](../../protected_tags.md).
- [Tags API](../../../../api/tags.md).
