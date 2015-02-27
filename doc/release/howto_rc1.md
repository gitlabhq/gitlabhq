# How to create RC1

The RC1 release comes with the task to update the installation and upgrade docs. Be mindful that there might already be merge requests for this on GitLab or GitHub.

### 1. Update the installation guide

1. Check if it references the correct branch `x-x-stable` (doesn't exist yet, but that is okay)
1. Check the [GitLab Shell version](/lib/tasks/gitlab/check.rake#L782)
1. Check the [Git version](/lib/tasks/gitlab/check.rake#L794)
1. There might be other changes. Ask around.

### 2. Create update guides

[Follow this guide](howto_update_guides.md) to create update guides.

### 3. Code quality indicators

Make sure the code quality indicators are green / good.

- [![Build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

- [![Build Status](https://semaphoreapp.com/api/v1/projects/2f1a5809-418b-4cc2-a1f4-819607579fe7/243338/badge.png)](https://semaphoreapp.com/gitlabhq/gitlabhq) (master branch)

- [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

- [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available)

- [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### 4. Run release tool

**Make sure EE `master` has latest changes from CE `master`**

Get release tools

```
git clone git@dev.gitlab.org:gitlab/release-tools.git
cd release-tools
```

Release candidate creates stable branch from master.
So we need to sync master branch between all CE, EE and CI remotes.

```
bundle exec rake sync
```

Create release candidate and stable branch:

```
bundle exec rake release["x.x.0.rc1"]
```

Now developers can use master for merging new features.
So you should use stable branch for future code changes related to release.
