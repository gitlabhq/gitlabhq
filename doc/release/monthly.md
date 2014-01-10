# Things to do when creating new monthly minor or major release
NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

## Install guide up to date?

* References correct GitLab branch `x-x-stable` and correct GitLab shell tag?

## Make upgrade guide

### From x.x to x.x

#### 0. Any major changes? Database updates? Web server change? File structure changes?

#### 1. Make backup

#### 2. Stop server

#### 3. Do users need to update dependencies like `git`?

#### 4. Get latest code

#### 5. Does GitLab shell need to be updated?

#### 6. Install libs, migrations, etc.

#### 7. Any config files updated since last release?

Check if any of these changed since last release (~22nd of last month depending on when last release branch was created):

* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/nginx/gitlab
* https://gitlab.com/gitlab-org/gitlab-shell/commits/master/config.yml.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/gitlab.yml.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/unicorn.rb.example
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.mysql
* https://gitlab.com/gitlab-org/gitlab-ce/commits/master/config/database.yml.postgresql

#### 8. Need to update init script?

Check if changed since last release (~22nd of last month depending on when last release branch was created): https://gitlab.com/gitlab-org/gitlab-ce/commits/master/lib/support/init.d/gitlab

#### 9. Start application

#### 10. Check application status

## Make sure the code quality indicatiors are good

* [![build status](http://ci.gitlab.org/projects/1/status.png?ref=master)](http://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

* [![build status](https://secure.travis-ci.org/gitlabhq/gitlabhq.png)](https://travis-ci.org/gitlabhq/gitlabhq) on travis-ci.org (master branch)

* [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.png)](https://codeclimate.com/github/gitlabhq/gitlabhq)

* [![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.png)](https://gemnasium.com/gitlabhq/gitlabhq) this button can be yellow (small updates are available) but must not be red (a security fix or an important update is available)

* [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq)

## Make a release branch

After making the release branch new commits are cherry-picked from master. When the release gets closer we get more selective what is cherry-picked. The days of the month are approximately as follows:

* 17th: feature freeze (branch and stop merging new features)
* 18th: UI freeze (stop cherry-picking changes to the user interface)
* 19th: code freeze (stop cherry-picking non-essential code improvements)
* 20th: release candidate 1 (tag and tweet about x.x.rc1)
* 21st: release candidate 2 (optional, only if rc1 had problems)
* 22nd: release (update VERSION and CHANGELOG, tag, blog and tweet)

# Write a blog post

* Mention what GitLab is on the second line: GitLab is open source software to collaborate on code.
* Select and thank the the Most Valuable Person (MVP) of this release.
* Add a note if there are security fixes: This release fixes an important security issue and we advise everyone to upgrade as soon as possible.
