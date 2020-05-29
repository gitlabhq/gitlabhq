---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: tutorial
---

NOTE: **Note:**
This document has not been updated recently and could be out of date. For the latest documentation, see the [GitLab CI/CD](../README.md) page and the [GitLab CI/CD Pipeline Configuration Reference](../yaml/README.md).

# Test a Clojure application with GitLab CI/CD

This example will guide you how to run tests on your Clojure application.

You can view or fork the [example source](https://gitlab.com/dzaporozhets/clojure-web-application) and view the logs of its past [CI jobs](https://gitlab.com/dzaporozhets/clojure-web-application/builds?scope=finished).

## Configure the project

This is what the `.gitlab-ci.yml` file looks like for this project:

```yaml
variables:
  POSTGRES_DB: sample-test
  DATABASE_URL: "postgresql://postgres@postgres:5432/sample-test"

before_script:
  - apt-get update -y
  - apt-get install default-jre postgresql-client -y
  - wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
  - chmod a+x lein
  - export LEIN_ROOT=1
  - PATH=$PATH:.
  - lein deps
  - lein migratus migrate

test:
  script:
    - lein test
```

In `before_script`, we install JRE and [Leiningen](https://leiningen.org/).

The sample project uses the [migratus](https://github.com/yogthos/migratus) library to manage database migrations, and
we have added a database migration as the last step of `before_script`.

You can use public runners available on `gitlab.com` for testing your application with this configuration.
