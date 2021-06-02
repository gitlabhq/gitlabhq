---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Subtree **(FREE)**

- Used when there are nested repositories.
- Not recommended when the amount of dependencies is too large.
- For these cases we need a dependency control system.
- Command are painfully long so aliases are necessary.

## Subtree Aliases

- Add: `git subtree add --prefix <target-folder> <url> <branch> --squash`
- Pull: `git subtree pull --prefix <target-folder> <url> <branch> --squash`
- Push: `git subtree add --prefix <target-folder> <url> <branch>`
- Ex: `git config alias.sbp 'subtree pull --prefix st /
  git@gitlab.com:balameb/subtree-nested-example.git master --squash'`

```shell
  # Add an alias
  # Add
  git config alias.sba 'subtree add --prefix st /
  git@gitlab.com:balameb/subtree-nested-example.git master --squash'
  # Pull
  git config alias.sbpl 'subtree pull --prefix st /
  git@gitlab.com:balameb/subtree-nested-example.git master --squash'
  # Push
  git config alias.sbph 'subtree push --prefix st /
  git@gitlab.com:balameb/subtree-nested-example.git master'

  # Adding this subtree adds a st dir with a readme
  git sba
  vi st/README.md
  # Edit file
  git status shows differences

```

```shell
  # Adding, or committing won't change the sub repo at remote
  # even if we push
  git add -A
  git commit -m "Adding to subtree readme"

  # Push to subtree repo
  git sbph
  # now we can check our remote sub repo
```
