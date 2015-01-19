# How to create RC1

The RC1 release comes with the task to update the installation and upgrade docs. Be mindful that there might already be merge requests for this on GitLab or GitHub.

### 1. Update the installation guide

1. Check if it references the correct branch `x-x-stable` (doesn't exist yet, but that is okay)
1. Check the [GitLab Shell version](/lib/tasks/gitlab/check.rake#L782)
1. Check the [Git version](/lib/tasks/gitlab/check.rake#L794)
1. There might be other changes. Ask around.

### 2. Create update guides

1. Create: CE update guide from previous version. Like `7.3-to-7.4.md`
1. Create: CE to EE update guide in EE repository for latest version.
1. Update: `6.x-or-7.x-to-7.x.md` to latest version.
1. Create: CI update guide from previous version

It's best to copy paste the previous guide and make changes where necessary.
The typical steps are listed below with any points you should specifically look at.

#### 0. Any major changes?

List any major changes here, so the user is aware of them before starting to upgrade. For instance:

- Database updates
- Web server changes
- File structure changes

#### 1. Stop server

#### 2. Make backup

#### 3. Do users need to update dependencies like `git`?

- Check if the [GitLab Shell version](/lib/tasks/gitlab/check.rake#L782) changed since the last release.

- Check if the [Git version](/lib/tasks/gitlab/check.rake#L794) changed since the last release.

#### 4. Get latest code

#### 5. Does GitLab shell need to be updated?

#### 6. Install libs, migrations, etc.

#### 7. Any config files updated since last release?

Check if any of these changed since last release:

- [lib/support/nginx/gitlab](/lib/support/nginx/gitlab)
- [lib/support/nginx/gitlab-ssl](/lib/support/nginx/gitlab-ssl)
- <https://gitlab.com/gitlab-org/gitlab-shell/commits/master/config.yml.example>
- [config/gitlab.yml.example](/config/gitlab.yml.example)
- [config/unicorn.rb.example](/config/unicorn.rb.example)
- [config/database.yml.mysql](/config/database.yml.mysql)
- [config/database.yml.postgresql](/config/database.yml.postgresql)
- [config/initializers/rack_attack.rb.example](/config/initializers/rack_attack.rb.example)
- [config/resque.yml.example](/config/resque.yml.example)

#### 8. Need to update init script?

Check if the `init.d/gitlab` script changed since last release: [lib/support/init.d/gitlab](/lib/support/init.d/gitlab)

#### 9. Start application

#### 10. Check application status

### 3. Code quality indicators

Make sure the code quality indicators are green / good.

- [![Build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

- [![Build Status](https://semaphoreapp.com/api/v1/projects/2f1a5809-418b-4cc2-a1f4-819607579fe7/243338/badge.png)](https://semaphoreapp.com/gitlabhq/gitlabhq) (master branch)

- [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

- [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available)

- [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

### 4. Run release tool for CE and EE

**Make sure EE `master` has latest changes from CE `master`**

Get release tools

```
git clone git@dev.gitlab.org:gitlab/release-tools.git
cd release-tools
```

Release candidate creates stable branch from master. 
So we need to sync master branch between all CE remotes. Also do same for EE.

```
bundle exec rake sync
```

Create release candidate and stable branch:

```
bundle exec rake release["x.x.0.rc1"]
```

Now developers can use master for merging new features.
So you should use stable branch for future code chages related to release.


### 5. Release GitLab CI RC1

Add to your local `gitlab-ci/.git/config`:

```
[remote "public"]
    url = none
    pushurl = git@dev.gitlab.org:gitlab/gitlab-ci.git
    pushurl = git@gitlab.com:gitlab-org/gitlab-ci.git
    pushurl = git@github.com:gitlabhq/gitlab-ci.git
```

* Create a stable branch `x-y-stable`
* Bump VERSION to `x.y.0.rc1`
* `git tag -a v$(cat VERSION) -m "Version $(cat VERSION)"`
* `git push public x-y-stable v$(cat VERSION)`

