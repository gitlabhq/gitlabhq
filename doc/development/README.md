# Development

## Outside of docs

- [CONTRIBUTING.md](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md) main contributing guide
- [PROCESS.md](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/PROCESS.md) contributing process
- [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/README.md) to install a development version

## Styleguides

- [API styleguide](api_styleguide.md) Use this styleguide if you are
  contributing to the API.
- [Documentation styleguide](doc_styleguide.md) Use this styleguide if you are
  contributing to documentation.
- [SQL Migration Style Guide](migration_style_guide.md) for creating safe SQL migrations
- [Testing standards and style guidelines](testing.md)
- [UX guide](ux_guide/index.md) for building GitLab with existing CSS styles and elements
- [Frontend guidelines](frontend.md)
- [SQL guidelines](sql.md) for working with SQL queries
- [Sidekiq guidelines](sidekiq_style_guide.md) for working with Sidekiq workers

## Process

- [Generate a changelog entry with `bin/changelog`](changelog.md)
- [Limit conflicts with EE when developing on CE](limit_ee_conflicts.md)
- [Code review guidelines](code_review.md) for reviewing code and having code reviewed.
- [Merge request performance guidelines](merge_request_performance_guidelines.md)
  for ensuring merge requests do not negatively impact GitLab performance

## Backend howtos

- [Architecture](architecture.md) of GitLab
- [CI setup](ci_setup.md) for testing GitLab
- [Gotchas](gotchas.md) to avoid
- [How to dump production data to staging](db_dump.md)
- [Instrumentation](instrumentation.md)
- [Performance guidelines](performance.md)
- [Rake tasks](rake_tasks.md) for development
- [Shell commands](shell_commands.md) in the GitLab codebase
- [Sidekiq debugging](sidekiq_debugging.md)
- [Object state models](object_state_models.md)

## Databases

- [What requires downtime?](what_requires_downtime.md)
- [Adding database indexes](adding_database_indexes.md)
- [Post Deployment Migrations](post_deployment_migrations.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance
