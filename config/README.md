# Configuration files Documentation

Note that most configuration files (`config/*.*`) committed into
[gitlab-ce](https://gitlab.com/gitlab-org/gitlab-ce) **would not be used** for
[omnibus-gitlab](https://gitlab.com/gitlab-org/omnibus-gitlab). Configuration
files committed into gitlab-ce are only used for development.

## gitlab.yml

You could find most of GitLab configuration here.

## mail_room.yml

It's intended to be an ERB file because `mail_room` would use ERB to evaluate
it before parsing it as a YAML file. It would try to read values from
`gitlab.yml` so you should configure it there.

## resque.yml

It's called `resque.yml` for historical reason, and we're not using rescue
at the moment. It's served as a **Redis configuration file** instead.
