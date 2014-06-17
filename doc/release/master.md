# How to push GitLab CE master branch to all remotes.

The source code of GitLab is available on multiple servers (with GitLab.com as the canonical source).
Synchronization between the repo's is done by the lead developer if there is no rush.
This happens a few times per workday on average.
If somebody else with access to all repo's wants to do it the instructions are below.
This is just to distribute changes, not to make them.

## Add this to `.bashrc` or [your dotfiles](https://github.com/dosire/dotfiles/commit/52803ce3ac60d57632164b7713ff0041e86fa26c)

```bash
gpa ()
{
  git push origin ${1:-master} && git push gh ${1:-master} && git push gl ${1:-master}
}
```

## Then add remotes to your local repo

```bash
cd my-gitlab-ce-repo

git remote add origin git@dev.gitlab.org:gitlab/gitlabhq.git
git remote add gh git@github.com:gitlabhq/gitlabhq.git
git remote add gl git@gitlab.com:gitlab-org/gitlab-ce.git
```

## Push to all remotes

```bash
gpa
```

