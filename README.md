# ![logo](https://about.gitlab.com/images/gitlab_logo.png) GitLab

## Open source software to collaborate on code

![Animated screenshots](https://about.gitlab.com/images/animated/compiled.gif)

- Manage Git repositories with fine grained access controls that keep your code secure
- Perform code reviews and enhance collaboration with merge requests
- Each project can also have an issue tracker and a wiki
- Used by more than 100,000 organizations, GitLab is the most popular solution to manage Git repositories on-premises
- Completely free and open source (MIT Expat license)
- Powered by Ruby on Rails

## Canonical source

- The source of GitLab Community Edition is [hosted on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/) and there are mirrors to make [contributing](CONTRIBUTING.md) as easy as possible.

## Code status

- [![build status](https://ci.gitlab.org/projects/1/status.png?ref=master)](https://ci.gitlab.org/projects/1?ref=master) on ci.gitlab.org (master branch)

- [![Build Status](https://semaphoreapp.com/api/v1/projects/2f1a5809-418b-4cc2-a1f4-819607579fe7/243338/badge.png)](https://semaphoreapp.com/gitlabhq/gitlabhq)

- [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.svg)](https://codeclimate.com/github/gitlabhq/gitlabhq)

- [![Coverage Status](https://coveralls.io/repos/gitlabhq/gitlabhq/badge.png?branch=master)](https://coveralls.io/r/gitlabhq/gitlabhq?branch=master)

- [![PullReview stats](https://www.pullreview.com/gitlab/gitlab-org/gitlab-ce/badges/master.svg?)](https://www.pullreview.com/gitlab.gitlab.com/gitlab-org/gitlab-ce/reviews/master)

## Website

On [about.gitlab.com](https://about.gitlab.com/) you can find more information about:

- [Subscriptions](https://about.gitlab.com/subscription/)
- [Consultancy](https://about.gitlab.com/consultancy/)
- [Community](https://about.gitlab.com/community/)
- [Hosted GitLab.com](https://about.gitlab.com/gitlab-com/) use GitLab as a free service
- [GitLab Enterprise Edition](https://about.gitlab.com/gitlab-ee/) with additional features aimed at larger organizations.
- [GitLab CI](https://about.gitlab.com/gitlab-ci/) a continuous integration (CI) server that is easy to integrate with GitLab.

## Requirements

- Ubuntu/Debian/CentOS/RHEL**
- ruby 2.0+
- git 1.7.10+
- redis 2.0+
- MySQL or PostgreSQL

** More details are in the [requirements doc](doc/install/requirements.md).

## Installation

Please see [the installation page on the GitLab website](https://about.gitlab.com/installation/) for the various options.
Since a manual installation is a lot of work and error prone we strongly recommend the fast and reliable [Omnibus package installation](https://about.gitlab.com/downloads/) (deb/rpm).
You can access new installation with the login `root` and password `5iveL!fe`, after login you are required to set a unique password.

## Third-party applications

There are a lot of applications and API wrappers for GitLab.
Find them [on our website](https://about.gitlab.com/applications/).

## New versions

Since 2011 a minor or major version of GitLab is released on the 22nd of every month. Patch and security releases come out when needed.  New features are detailed on the [blog](https://about.gitlab.com/blog/) and in the [changelog](CHANGELOG). For more information about the release process see the release [documentation](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/release). Features that will likely be in the next releases can be found on the [feature request forum](http://feedback.gitlab.com/forums/176466-general) with the status [started](http://feedback.gitlab.com/forums/176466-general/status/796456) and [completed](http://feedback.gitlab.com/forums/176466-general/status/796457).

## Upgrading

For updating the the Omnibus installation please see the [update documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update.md). For manual installations there is an [upgrader script](doc/update/upgrader.md) and there are [upgrade guides](doc/update).

## Install a development environment

We recommend setting up your development environment with [the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
If you do not use the GitLab Development Development kit you need to install and setup all the dependencies yourself, this is a lot of work and error prone.
One small thing you also have to do when installing it yourself is to copy the example development unicorn configuration file:

    cp config/unicorn.rb.example.development config/unicorn.rb

Instructions on how to start Gitlab and how to run the tests can be found in the [development section of the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit#development).

## Documentation

All documentation can be found on [doc.gitlab.com/ce/](http://doc.gitlab.com/ce/).

## Getting help

Please see [Getting help for GitLab](https://about.gitlab.com/getting-help/) on our website for the many options to get help.

## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)

## Is it awesome?

Thanks for [asking this question](https://twitter.com/supersloth/status/489462789384056832) Joshua.
[These people](https://twitter.com/gitlab/favorites) seem to like it.
