---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tags **(FREE)**

Tags help you mark certain deployments and releases for later
reference. Git supports two types of tags:

- Annotated tags: An unchangeable part of Git history.
- Lightweight (soft) tags: Tags that can be set and removed as needed.

Many projects combine an annotated release tag with a stable branch. Consider
setting deployment or release tags automatically.

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

## Tags sample workflow

1. Create a lightweight tag.
1. Create an annotated tag.
1. Push the tags to the remote repository.

```shell
git checkout main

# Lightweight tag
git tag my_lightweight_tag

# Annotated tag
git tag -a v1.0 -m 'Version 1.0'

# Show list of the existing tags
git tag

git push origin --tags
```

## Related topics

- [Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging) Git reference page
- [Protected tags](../../protected_tags.md)
- [Tags API](../../../../api/tags.md)
