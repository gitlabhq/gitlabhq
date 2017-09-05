# GitLab

[![Build status](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/build.svg)](https://gitlab.com/gitlab-org/gitlab-ce/commits/master)
[![Overall test coverage](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg)](https://gitlab.com/gitlab-org/gitlab-ce/pipelines)
[![Dependency Status](https://gemnasium.com/gitlabhq/gitlabhq.svg)](https://gemnasium.com/gitlabhq/gitlabhq)
[![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.svg)](https://codeclimate.com/github/gitlabhq/gitlabhq)
[![Core Infrastructure Initiative Best Practices](https://bestpractices.coreinfrastructure.org/projects/42/badge)](https://bestpractices.coreinfrastructure.org/projects/42)
[![Gitter](https://badges.gitter.im/gitlabhq/gitlabhq.svg)](https://gitter.im/gitlabhq/gitlabhq?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## Test coverage

- [![Ruby coverage](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg?job=coverage)](https://gitlab-org.gitlab.io/gitlab-ce/coverage-ruby) Ruby
- [![JavaScript coverage](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg?job=karma)](https://gitlab-org.gitlab.io/gitlab-ce/coverage-javascript) JavaScript

## Canonical source

The canonical source of GitLab Community Edition is [hosted on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/).

## Open source software to collaborate on code

To see how GitLab looks please see the [features page on our website](https://about.gitlab.com/features/).

- Manage Git repositories with fine grained access controls that keep your code secure
- Perform code reviews and enhance collaboration with merge requests
- Complete continuous integration (CI) and CD pipelines to builds, test, and deploy your applications
- Each project can also have an issue tracker, issue board, and a wiki
- Used by more than 100,000 organizations, GitLab is the most popular solution to manage Git repositories on-premises
- Completely free and open source (MIT Expat license)

## Hiring

We're hiring developers, support people, and production engineers all the time, please see our [jobs page](https://about.gitlab.com/jobs/).

## Editions

There are two editions of GitLab:

- GitLab Community Edition (CE) is available freely under the MIT Expat license.
- GitLab Enterprise Edition (EE) includes [extra features](https://about.gitlab.com/products/#compare-options) that are more useful for organizations with more than 100 users. To use EE and get official support please [become a subscriber](https://about.gitlab.com/products/).

## Website

On [about.gitlab.com](https://about.gitlab.com/) you can find more information about:

- [Subscriptions](https://about.gitlab.com/pricing/)
- [Consultancy](https://about.gitlab.com/consultancy/)
- [Community](https://about.gitlab.com/community/)
- [Hosted GitLab.com](https://about.gitlab.com/gitlab-com/) use GitLab as a free service
- [GitLab Enterprise Edition](https://about.gitlab.com/features/#enterprise) with additional features aimed at larger organizations.
- [GitLab CI](https://about.gitlab.com/gitlab-ci/) a continuous integration (CI) server that is easy to integrate with GitLab.

## Requirements

Please see the [requirements documentation](doc/install/requirements.md) for system requirements and more information about the supported operating systems.

## Installation

The recommended way to install GitLab is with the [Omnibus packages](https://about.gitlab.com/downloads/) on our package server.
Compared to an installation from source, this is faster and less error prone.
Just select your operating system, download the respective package (Debian or RPM) and install it using the system's package manager.

There are various other options to install GitLab, please refer to the [installation page on the GitLab website](https://about.gitlab.com/installation/) for more information.

You can access a new installation with the login **`root`** and password **`5iveL!fe`**, after login you are required to set a unique password.

## Contributing

GitLab is an open source project and we are very happy to accept community contributions. Please refer to [CONTRIBUTING.md](/CONTRIBUTING.md) for details.

## Install a development environment

To work on GitLab itself, we recommend setting up your development environment with [the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
If you do not use the GitLab Development Kit you need to install and setup all the dependencies yourself, this is a lot of work and error prone.
One small thing you also have to do when installing it yourself is to copy the example development unicorn configuration file:

    cp config/unicorn.rb.example.development config/unicorn.rb

Instructions on how to start GitLab and how to run the tests can be found in the [getting started section of the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit#getting-started).

## Software stack

GitLab is a Ruby on Rails application that runs on the following software:

- Ubuntu/Debian/CentOS/RHEL/OpenSUSE
- Ruby (MRI) 2.3
- Git 2.8.4+
- Redis 2.8+
- PostgreSQL (preferred) or MySQL

For more information please see the [architecture documentation](https://docs.gitlab.com/ce/development/architecture.html).

## UX design

Please adhere to the [UX Guide](doc/development/ux_guide/index.md) when creating designs and implementing code.

## Third-party applications

There are a lot of [third-party applications integrating with GitLab](https://about.gitlab.com/applications/). These include GUI Git clients, mobile applications and API wrappers for various languages.

## GitLab release cycle

For more information about the release process see the [release documentation](https://gitlab.com/gitlab-org/release-tools/blob/master/README.md).

## Upgrading

For upgrading information please see our [update page](https://about.gitlab.com/update/).

## Documentation

All documentation can be found on [docs.gitlab.com/ce/](https://docs.gitlab.com/ce/).

## Getting help

Please see [Getting help for GitLab](https://about.gitlab.com/getting-help/) on our website for the many options to get help.

## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)

## Is it awesome?

Thanks for [asking this question](https://twitter.com/supersloth/status/489462789384056832) Joshua.
[These people](https://twitter.com/gitlab/likes) seem to like it.
