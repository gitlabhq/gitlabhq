---
comments: false
---

# Tags

----------

- Useful for marking deployments and releases
- Annotated tags are an unchangeable part of Git history
- Soft/lightweight tags can be set and removed at will
- Many projects combine an anotated release tag with a stable branch
- Consider setting deployment/release tags automatically

----------

# Tags

- Create a lightweight tag
- Create an annotated tag
- Push the tags to the remote repository

**Additional resources**

[http://git-scm.com/book/en/Git-Basics-Tagging](http://git-scm.com/book/en/Git-Basics-Tagging)

----------

# Commands

```
git checkout master

# Lightweight tag
git tag my_lightweight_tag

# Annotated tag
git tag -a v1.0 -m ‘Version 1.0’
git tag

git push origin --tags
```
