---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rake tasks for developers

Rake tasks are available for developers and others contributing to GitLab.

## Set up database with developer seeds

Note that if your database user does not have advanced privileges, you must create the database manually before running this command.

```shell
bundle exec rake setup
```

The `setup` task is an alias for `gitlab:setup`.
This tasks calls `db:reset` to create the database, and calls `db:seed_fu` to seed the database.
`db:setup` calls `db:seed` but this does nothing.

### Environment variables

**MASS_INSERT**: Create millions of users (2m), projects (5m) and its
relations. It's highly recommended to run the seed with it to catch slow queries
while developing. Expect the process to take up to 20 extra minutes.

See also [Mass inserting Rails models](mass_insert.md).

**LARGE_PROJECTS**: Create large projects (through import) from a predefined set of URLs.

### Seeding issues for all or a given project

You can seed issues for all or a given project with the `gitlab:seed:issues`
task:

```shell
# All projects
bin/rake gitlab:seed:issues

# A specific project
bin/rake "gitlab:seed:issues[group-path/project-path]"
```

By default, this seeds an average of 2 issues per week for the last 5 weeks per
project.

#### Seeding issues for Insights charts **(ULTIMATE)**

You can seed issues specifically for working with the
[Insights charts](../user/group/insights/index.md) with the
`gitlab:seed:insights:issues` task:

```shell
# All projects
bin/rake gitlab:seed:insights:issues

# A specific project
bin/rake "gitlab:seed:insights:issues[group-path/project-path]"
```

By default, this seeds an average of 10 issues per week for the last 52 weeks
per project. All issues are also randomly labeled with team, type, severity,
and priority.

#### Seeding groups with subgroups

You can seed groups with subgroups that contain milestones/projects/issues
with the `gitlab:seed:group_seed` task:

```shell
bin/rake "gitlab:seed:group_seed[subgroup_depth, username]"
```

Group are additionally seeded with epics if GitLab instance has epics feature available.

#### Seeding custom metrics for the monitoring dashboard

A lot of different types of metrics are supported in the monitoring dashboard.

To import these metrics, you can run:

```shell
bundle exec rake 'gitlab:seed:development_metrics[your_project_id]'
```

### Automation

If you're very sure that you want to **wipe the current database** and refill
seeds, you can set the `FORCE` environment variable to `yes`:

```shell
FORCE=yes bundle exec rake setup
```

This will skip the action confirmation/safety check, saving you from answering
`yes` manually.

### Discard `stdout`

Since the script would print a lot of information, it could be slowing down
your terminal, and it would generate more than 20G logs if you just redirect
it to a file. If we don't care about the output, we could just redirect it to
`/dev/null`:

```shell
echo 'yes' | bundle exec rake setup > /dev/null
```

Note that since you can't see the questions from `stdout`, you might just want
to `echo 'yes'` to keep it running. It would still print the errors on `stderr`
so no worries about missing errors.

### Extra Project seed options

There are a few environment flags you can pass to change how projects are seeded

- `SIZE`: defaults to `8`, max: `32`. Amount of projects to create.
- `LARGE_PROJECTS`: defaults to false. If set, clones 6 large projects to help with testing.
- `FORK`: defaults to false. If set to `true`, forks `torvalds/linux` five times. Can also be set to an existing project `full_path` to fork that instead.

## Run tests

In order to run the test you can use the following commands:

- `bin/rake spec` to run the RSpec suite
- `bin/rake spec:unit` to run only the unit tests
- `bin/rake spec:integration` to run only the integration tests
- `bin/rake spec:system` to run only the system tests
- `bin/rake karma` to run the Karma test suite

`bin/rake spec` takes significant time to pass.
Instead of running the full test suite locally, you can save a lot of time by running
a single test or directory related to your changes. After you submit a merge request,
CI runs full test suite for you. Green CI status in the merge request means
full test suite is passed.

You can't run `rspec .` since this tries to run all the `_spec.rb`
files it can find, also the ones in `/tmp`

You can pass RSpec command line options to the `spec:unit`,
`spec:integration`, and `spec:system` tasks. For example, `bin/rake "spec:unit[--tag ~geo --dry-run]"`.

For an RSpec test, to run a single test file you can run:

```shell
bin/rspec spec/controllers/commit_controller_spec.rb
```

To run several tests inside one directory:

- `bin/rspec spec/requests/api/` for the RSpec tests if you want to test API only

### Run RSpec tests which failed in Merge Request pipeline on your machine

If your Merge Request pipeline failed with RSpec test failures,
you can run all the failed tests on your machine with the following Rake task:

```shell
bin/rake spec:merge_request_rspec_failure
```

There are a few caveats for this Rake task:

- You need to be on the same branch on your machine as the source branch of the Merge Request.
- The pipeline must have been completed.
- You may need to wait for the test report to be parsed and retry again.

This Rake task depends on the [unit test reports](../ci/unit_test_reports.md) feature,
which only gets parsed when it is requested for the first time.

### Speed up tests, Rake tasks, and migrations

[Spring](https://github.com/rails/spring) is a Rails application pre-loader. It
speeds up development by keeping your application running in the background so
you don't need to boot it every time you run a test, Rake task or migration.

If you want to use it, you must export the `ENABLE_SPRING` environment
variable to `1`:

```shell
export ENABLE_SPRING=1
```

Alternatively you can use the following on each spec run,

```shell
bundle exec spring rspec some_spec.rb
```

## Compile Frontend Assets

You shouldn't ever need to compile frontend assets manually in development, but
if you ever need to test how the assets get compiled in a production
environment you can do so with the following command:

```shell
RAILS_ENV=production NODE_ENV=production bundle exec rake gitlab:assets:compile
```

This compiles and minifies all JavaScript and CSS assets and copy them along
with all other frontend assets (images, fonts, etc) into `/public/assets` where
they can be easily inspected.

## Emoji tasks

To update the Emoji aliases file (used for Emoji autocomplete), run the
following:

```shell
bundle exec rake gemojione:aliases
```

To update the Emoji digests file (used for Emoji autocomplete), run the
following:

```shell
bundle exec rake gemojione:digests
```

This updates the file `fixtures/emojis/digests.json` based on the currently
available Emoji.

To generate a sprite file containing all the Emoji, run:

```shell
bundle exec rake gemojione:sprite
```

If new emoji are added, the sprite sheet may change size. To compensate for
such changes, first generate the `emoji.png` sprite sheet with the above Rake
task, then check the dimensions of the new sprite sheet and update the
`SPRITESHEET_WIDTH` and `SPRITESHEET_HEIGHT` constants accordingly.

## Update project templates

Starting a project from a template needs this project to be exported. On a
up to date main branch run:

```shell
gdk start
bundle exec rake gitlab:update_project_templates
git checkout -b update-project-templates
git add vendor/project_templates
git commit
git push -u origin update-project-templates
```

Now create a merge request and merge that to main.

To update just a single template instead of all of them, specify the template name
between square brackets. For example, for the `cluster_management` template, run:

```shell
bundle exec rake gitlab:update_project_templates\[cluster_management\]
```

## Generate route lists

To see the full list of API routes, you can run:

```shell
bundle exec rake grape:path_helpers
```

The generated list includes a full list of API endpoints and functional
RESTful API verbs.

For the Rails controllers, run:

```shell
bundle exec rails routes
```

Since these take some time to create, it's often helpful to save the output to
a file for quick reference.

## Show obsolete `ignored_columns`

To see a list of all obsolete `ignored_columns` run:

```shell
bundle exec rake db:obsolete_ignored_columns
```

Feel free to remove their definitions from their `ignored_columns` definitions.

## Validate GraphQL queries

To check the validity of one or more of our front-end GraphQL queries,
run:

```shell
# Validate all queries
bundle exec rake gitlab::graphql:validate
# Validate one query
bundle exec rake gitlab::graphql:validate[path/to/query.graphql]
# Validate a directory
bundle exec rake gitlab::graphql:validate[path/to/queries]
```

This prints out a report with an entry for each query, explaining why
each query is invalid if it fails to pass validation.

We strip out `@client` fields during validation so it is important to mark
client fields with the `@client` directive to avoid false positives.

## Analyze GraphQL queries

Analogous to `ANALYZE` in SQL, we can run `gitlab:graphql:analyze` to
estimate the of the cost of running a query.

Usage:

```shell
# Analyze all queries
bundle exec rake gitlab::graphql:analyze
# Analyze one query
bundle exec rake gitlab::graphql:analyze[path/to/query.graphql]
# Analyze a directory
bundle exec rake gitlab::graphql:analyze[path/to/queries]
```

This prints out a report for each query, including the complexity
of the query if it is valid.

The complexity depends on the arguments in some cases, so the reported
complexity is a best-effort assessment of the upper bound.

## Update GraphQL documentation and schema definitions

To generate GraphQL documentation based on the GitLab schema, run:

```shell
bundle exec rake gitlab:graphql:compile_docs
```

In its current state, the Rake task:

- Generates output for GraphQL objects.
- Places the output at `doc/api/graphql/reference/index.md`.

This uses some features from `graphql-docs` gem like its schema parser and helper methods.
The docs generator code comes from our side giving us more flexibility, like using Haml templates and generating Markdown files.

To edit the content, you may need to edit the following:

- The template. You can edit the template at `lib/gitlab/graphql/docs/templates/default.md.haml`.
  The actual renderer is at `Gitlab::Graphql::Docs::Renderer`.
- The applicable `description` field in the code, which
  [Updates machine-readable schema files](#update-machine-readable-schema-files),
  which is then used by the `rake` task described earlier.

`@parsed_schema` is an instance variable that the `graphql-docs` gem expects to have available.
`Gitlab::Graphql::Docs::Helper` defines the `object` method we currently use. This is also where you
should implement any new methods for new types you'd like to display.

### Update machine-readable schema files

To generate GraphQL schema files based on the GitLab schema, run:

```shell
bundle exec rake gitlab:graphql:schema:dump
```

This uses GraphQL Ruby's built-in Rake tasks to generate files in both [IDL](https://www.prisma.io/blog/graphql-sdl-schema-definition-language-6755bcb9ce51) and JSON formats.

### Update documentation and schema definitions

The following command combines the intent of [Update GraphQL documentation and schema definitions](#update-graphql-documentation-and-schema-definitions) and [Update machine-readable schema files](#update-machine-readable-schema-files):

```shell
bundle exec rake gitlab:graphql:update_all
```
