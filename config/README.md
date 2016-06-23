# Configuration files Documentation

Note that most configuration files (`config/*.*`) committed into
[gitlab-ce](https://gitlab.com/gitlab-org/gitlab-ce) **will not be used** for
[omnibus-gitlab](https://gitlab.com/gitlab-org/omnibus-gitlab). Configuration
files committed into gitlab-ce are only used for development.

## gitlab.yml

You can find most of GitLab configuration settings here.

## mail_room.yml

This file is actually an YML wrapped inside an ERB file to enable templated
values to be specified from `gitlab.yml`. mail_room loads this file first as
an ERB file and then loads the resulting YML as its configuration.

## resque.yml

This file is called `resque.yml` for historical reasons. We are **NOT**
using Resque at the moment. It is used to specify Redis configuration
values instead.
