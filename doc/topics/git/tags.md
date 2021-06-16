---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Tags **(FREE)**

Tags are useful for marking certain deployments and releases for later
reference. Git supports two types of tags:

- Annotated tags: An unchangeable part of Git history.
- Lightweight (soft) tags: Tags that can be set and removed as needed.

Many projects combine an annotated release tag with a stable branch. Consider
setting deployment or release tags automatically.

## Tags sample workflow

1. Create a lightweight tag.
1. Create an annotated tag.
1. Push the tags to the remote repository.

```shell
git checkout master

# Lightweight tag
git tag my_lightweight_tag

# Annotated tag
git tag -a v1.0 -m 'Version 1.0'

# Show list of the existing tags
git tag

git push origin --tags
```

## Additional resources

- [Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging) Git reference page
