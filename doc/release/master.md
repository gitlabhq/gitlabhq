# How to push GitLab CE master branch to all remotes.

Distribution to other repo's is done by Dmitriy if there is no rush. If a GitLab B.V. person wants to do it here are the instructions.

## Add this to `.bashrc`

```bash
gpa ()
{
  git push origin $1 && git push gh $1 && git push public $1
}
```

##  Then add remotes to your local repo

```bash
cd myrepo

git remote add origin git@dev.gitlab.org:gitlab/gitlabhq.git
git remote add gh  git@github.com:gitlabhq/gitlabhq.git
git remote add public git@gitlab.com:gitlab-org/gitlab-ce.git
```

## Pushto all remotes

```bash
gpa master
```

