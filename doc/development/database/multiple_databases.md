---
stage: Enablement
group: Sharding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multiple Databases

In order to scale GitLab, the GitLab application database
will be [decomposed into multiple
databases](https://gitlab.com/groups/gitlab-org/-/epics/6168).

## CI Database

Support for configuring the GitLab Rails application to use a distinct
database for CI tables was added in [GitLab
14.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64289). This
feature is still under development, and is not ready for production use.

By default, GitLab is configured to use only one main database. To
opt-in to use a main database, and CI database, modify the
`config/database.yml` file to have a `main` and a `ci` database
configurations. For example, given a `config/database.yml` like below:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_development
  host: /path/to/gdk/postgresql
  pool: 10
  prepared_statements: false
  variables:
    statement_timeout: 120s

test: &test
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_test
  host: /path/to/gdk/postgresql
  pool: 10
  prepared_statements: false
  variables:
    statement_timeout: 120s
```

Edit the `config/database.yml` to look like this:

```yaml
development:
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_development
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_development_ci
    migrations_paths: db/ci_migrate
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s

test: &test
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test_ci
    migrations_paths: db/ci_migrate
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
```

### Migrations

Any migrations that affect `Ci::BaseModel` models
and their tables must be placed in two directories for now:

- `db/migrate`
- `db/ci_migrate`

We aim to keep the schema for both tables the same across both databases.
