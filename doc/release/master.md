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

# Yanking packages from packages.gitlab.com

In case something went wrong with the release and there is a need to remove the packages you can yank the packages by following the
procedure described in [package cloud documentation](https://packagecloud.io/docs#yank_pkg).

You need to have:

1. `package_cloud` gem installed (sudo gem install package_cloud)
1. Email and password for packages.gitlab.com
1. Make sure that you are supplying the url to packages.gitlab.com (default is packagecloud.io)

Example of yanking a package:

```bash
package_cloud yank --url https://packages.gitlab.com gitlab/gitlab-ce/el/6 gitlab-ce-7.10.2~omnibus-1.x86_64.rpm
```

If you are attempting this for the first time the output will look something like:

```bash
Looking for repository at gitlab/gitlab-ce... No config file exists at /Users/marin/.packagecloud. Login to create one.
Email:
marin@gitlab.com
Password:

Got your token. Writing a config file to /Users/marin/.packagecloud... success!
success!
Attempting to yank package at gitlab/gitlab-ce/el/6/gitlab-ce-7.10.2~omnibus-1.x86_64.rpm...done!
```
