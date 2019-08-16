---
comments: false
type: reference
---

# Tags

- Useful for marking deployments and releases
- Annotated tags are an unchangeable part of Git history
- Soft/lightweight tags can be set and removed at will
- Many projects combine an annotated release tag with a stable branch
- Consider setting deployment/release tags automatically

## Tags sample workflow

- Create a lightweight tag
- Create an annotated tag
- Push the tags to the remote repository

```sh
git checkout master

# Lightweight tag
git tag my_lightweight_tag

# Annotated tag
git tag -a v1.0 -m ‘Version 1.0’
git tag

git push origin --tags
```

**Additional resources**

<https://git-scm.com/book/en/Git-Basics-Tagging>

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
