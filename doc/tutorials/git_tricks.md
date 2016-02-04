Based on https://gitlab.com/gitlab-org/gitlab-ce/issues/5986 here is an outline.

---

A pack of Git tricks that will leverage your Git-fu.

## Introduction


## Oh-my-zsh Git plugin

- https://github.com/robbyrussell/oh-my-zsh/wiki/Plugin:git
- https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/git/git.plugin.zsh

## Git extras

Enhance Git with more commands

- https://github.com/tj/git-extras

## Aliases

```ini
[alias]
  lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative
  lol = log --graph --decorate --pretty=oneline --abbrev-commit
```

## `.gitconfig` on steroids

- https://github.com/thoughtbot/dotfiles/blob/master/gitconfig
- https://github.com/thoughtbot/dotfiles/pull/377

---

1.  Set a global `.gitignore`:

    ```ini
    [core]
      excludesfile = /home/user/.gitignore
    ```

1.  Delete local branches that have been removed from remote on fetch/pull:

    ```ini
    [fetch]
      prune = true
    ```

1.  Gives you extra info when using Git submodules:

    ```ini
    [status]
      submodulesummary = 1
    ```

## Misc

1. Get a list of Git branches, ordered by most recent commit:

   ```
   git for-each-ref --sort=-committerdate refs/heads/
   ```

1. `@` is the same as `HEAD`:

    ```
    git show @~3
    ```

1. `-` refers to the branch you were on before the current one.
   Use it to checkout the previous branch ([source][dash]):

    ```sh
    % git branch
      master
    * rs-zenmode-refactor

    % git checkout master

    % git checkout -
    ```

1. Delete local branches which have already been merged into master
   ([source][del-merged]):

    ```
    git branch --merged master | grep -v "master" | xargs -n 1 git branch -d
    ```

1.  Delete all stale tracking branches for a remote:

    ```
    git remote prune origin
    ```

[del-merged]: http://stevenharman.net/git-clean-delete-already-merged-branches
[dash]: https://twitter.com/holman/status/530490167522779137
