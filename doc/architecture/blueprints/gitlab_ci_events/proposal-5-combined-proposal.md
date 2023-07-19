---
owning-stage: "~devops::verify"
description: 'GitLab CI Events Proposal 5: Combined proposal'
---

# GitLab CI Events Proposal 5: Combined proposal

In this proposal we have separate files for cohesive groups of events. The
files are being included into the main `.gitlab-ci.yml` configuration file.

```yaml
# my/events/packages.yaml

spec:
  events:
    - events/package/published
    - events/audit/package/*
  inputs:
    env:
---
do_something:
  script: ./run_for $[[ event.name ]] --env $[[ inputs.env ]]
  rules:
    - if: $[[ event.payload.package.name ]] == "my_package"
```

In the `.gitlab-ci.yml` file, we can enable the subscription:

```yaml
# .gitlab-ci.yml

include:
  - local: my/events/packages.yaml
    inputs:
      env: test

```

GitLab will detect changes in the included files, and parse their specs. All
the information required to define a subscription will be encapsulated in the
spec, hence we will not need to read a whole file. We can easily read `spec`
header and calculate its checksum what can become a workflow identifier.

Once we see a new identifier, we can redefine subscriptions for a particular
project and then to upsert them into the database.

We will use an efficient GIN index matching technique to match publishers with
the subscribers to run pipelines.

The syntax is also compatible with CI Components, and make it easier to define
components that will only be designed to run for events happening inside
GitLab.

## No entrypoint file variant

Another variant of this proposal is to move away from the single GitLab CI YAML
configuration file. In such case we would define another search **directory**,
like `.gitlab/workflows/` where we would store all YAML files.

We wouldn't need to `include` workflow / events files anywhere, because these
would be found by GitLab automatically. In order to implement this feature this
way we would need to extend features like "custom location for `.gitlab-ci.yml`
file".

Example, without using a main configuration file (the GitLab CI YAML file would
be still supported):

```yaml
# .gitlab/workflows/push.yml

spec:
  events:
    - events/repository/push
---
rspec-on-push:
  script: bundle exec rspec
```

```yaml
# .gitlab/workflows/merge_requests.yml

spec:
  events:
    - events/merge_request/push
---
rspec-on-mr-push:
  script: bundle exec rspec
```

```yaml
# .gitlab/workflows/schedules.yml

spec:
  events:
    - events/pipeline/schedule/run
---
smoke-test:
  script: bundle exec rspec --smoke
```
