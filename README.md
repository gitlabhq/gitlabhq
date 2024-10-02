# GitLab

## Canonical source

The canonical source of GitLab where all development takes place is [hosted on GitLab.com](https://gitlab.com/gitlab-org/gitlab).

If you wish to clone a copy of GitLab without proprietary code, you can use the read-only mirror of GitLab located at https://gitlab.com/gitlab-org/gitlab-foss/. However, please do not submit any issues and/or merge requests to that project.

## Free trial

You can request a free trial of GitLab Ultimate [on our website](https://about.gitlab.com/free-trial/).

## Open source software to collaborate on code

To see how GitLab looks please see the [features page on our website](https://about.gitlab.com/features/).

- Manage Git repositories with fine grained access controls that keep your code secure
- Perform code reviews and enhance collaboration with merge requests
- Complete continuous integration (CI) and continuous deployment/delivery (CD) pipelines to build, test, and deploy your applications
- Each project can also have an issue tracker, issue board, and a wiki
- Used by more than 100,000 organizations, GitLab is the most popular solution to manage Git repositories on-premises
- Completely free and open source (MIT Expat license)

## Editions

There are three editions of GitLab:

- GitLab Community Edition (CE) is available freely under the MIT Expat license.
- GitLab Enterprise Edition (EE) includes [extra features](https://about.gitlab.com/pricing/#compare-options) that are more useful for organizations with more than 100 users. To use EE and get official support please [become a subscriber](https://about.gitlab.com/pricing/).
- JiHu Edition (JH) tailored specifically for the [Chinese market](https://about.gitlab.cn/).

## Licensing

See the [LICENSE](LICENSE) file for licensing information as it pertains to
files in this repository.

## Hiring

We are hiring developers, support people, and production engineers all the time, please see our [jobs page](https://about.gitlab.com/jobs/).

## Website

On [about.gitlab.com](https://about.gitlab.com/) you can find more information about:

- [Subscriptions](https://about.gitlab.com/pricing/)
- [Professional Services](https://about.gitlab.com/services/)
- [Community](https://about.gitlab.com/community/)
- [Hosted GitLab.com](https://about.gitlab.com/gitlab-com/) use GitLab as a free service
- [GitLab Enterprise Edition](https://about.gitlab.com/features/#enterprise) with additional features aimed at larger organizations.
- [GitLab CI](https://about.gitlab.com/solutions/continuous-integration/) a continuous integration (CI) server that is easy to integrate with GitLab.

## Requirements

Please see the [requirements documentation](doc/install/requirements.md) for system requirements and more information about the supported operating systems.

## Installation

The recommended way to install GitLab is with the [Omnibus packages](https://about.gitlab.com/downloads/) on our package server.
Compared to an installation from source, this is faster and less error prone.
Just select your operating system, download the respective package (Debian or RPM) and install it using the system's package manager.

There are various other options to install GitLab, please refer to the [installation page on the GitLab website](https://about.gitlab.com/installation/) for more information.

## Contributing

GitLab is an open source project and we are very happy to accept community contributions. Please refer to [Contributing to GitLab page](https://about.gitlab.com/contributing/) for more details.

## Install a development environment

To work on GitLab itself, we recommend setting up your development environment with [the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit).
If you do not use the GitLab Development Kit you need to install and configure all the dependencies yourself, this is a lot of work and error prone.
One small thing you also have to do when installing it yourself is to copy the example development Puma configuration file:

```shell
cp config/puma.example.development.rb config/puma.rb
```

Instructions on how to start GitLab and how to run the tests can be found in the [getting started section of the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit#getting-started).

## Software stack

GitLab is a Ruby on Rails application that runs on the following software:

- Ubuntu/Debian/CentOS/RHEL/OpenSUSE
- Ruby (MRI) 3.2.5
- Git 2.33+
- Redis 6.0+
- PostgreSQL 14.9+

For more information please see the [architecture](https://docs.gitlab.com/ee/development/architecture.html) and [requirements](https://docs.gitlab.com/ee/install/requirements.html) documentation.

## UX design

Please adhere to the [UX Guide](https://design.gitlab.com/) when creating designs and implementing code.

## Third-party applications

There are a lot of [third-party applications integrating with GitLab](https://about.gitlab.com/applications/). These include GUI Git clients, mobile applications and API wrappers for various languages.

## GitLab release cycle

For more information about the release process see the [release documentation](https://gitlab.com/gitlab-org/release-tools/blob/master/README.md).

## Upgrading

For upgrading information please see our [update page](https://about.gitlab.com/update/).

## Documentation

All documentation can be found on <https://docs.gitlab.com>.

## Getting help

Please see [Getting help for GitLab](https://about.gitlab.com/getting-help/) on our website for the many options to get help.

## Why should I use GitLab?

Read [why our customers choose GitLab](https://about.gitlab.com/why-gitlab/).
