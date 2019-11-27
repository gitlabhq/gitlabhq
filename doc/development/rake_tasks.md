# Rake tasks for developers

## Set up db with developer seeds

Note that if your db user does not have advanced privileges you must create the db manually before running this command.

```
bundle exec rake setup
```

The `setup` task is an alias for `gitlab:setup`.
This tasks calls `db:reset` to create the database, and calls `db:seed_fu` to seed the database.
Note: `db:setup` calls `db:seed` but this does nothing.

### Env variables

**MASS_INSERT**: Create millions of users (2m), projects (5m) and its
relations. It's highly recommended to run the seed with it to catch slow queries
while developing. Expect the process to take up to 20 extra minutes.

**LARGE_PROJECTS**: Create large projects (through import) from a predefined set of urls.

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
per project. All issues will also be randomly labeled with team, type, severity,
and priority.

### Automation

If you're very sure that you want to **wipe the current database** and refill
seeds, you could:

``` shell
echo 'yes' | bundle exec rake setup
```

To save you from answering `yes` manually.

### Discard stdout

Since the script would print a lot of information, it could be slowing down
your terminal, and it would generate more than 20G logs if you just redirect
it to a file. If we don't care about the output, we could just redirect it to
`/dev/null`:

``` shell
echo 'yes' | bundle exec rake setup > /dev/null
```

Note that since you can't see the questions from stdout, you might just want
to `echo 'yes'` to keep it running. It would still print the errors on stderr
so no worries about missing errors.

### Extra Project seed options

There are a few environment flags you can pass to change how projects are seeded

- `SIZE`: defaults to `8`, max: `32`. Amount of projects to create.
- `LARGE_PROJECTS`: defaults to false. If set will clone 6 large projects to help with testing.
- `FORK`: defaults to false. If set to `true` will fork `torvalds/linux` five times. Can also be set to an existing project full_path and it will fork that instead.

## Run tests

In order to run the test you can use the following commands:

- `bin/rake spec` to run the rspec suite
- `bin/rake spec:unit` to run the only the unit tests
- `bin/rake spec:integration` to run the only the integration tests
- `bin/rake spec:system` to run the only the system tests
- `bin/rake karma` to run the Karma test suite

Note: `bin/rake spec` takes significant time to pass.
Instead of running full test suite locally you can save a lot of time by running
a single test or directory related to your changes. After you submit merge request
CI will run full test suite for you. Green CI status in the merge request means
full test suite is passed.

Note: You can't run `rspec .` since this will try to run all the `_spec.rb`
files it can find, also the ones in `/tmp`

Note: You can pass RSpec command line options to the `spec:unit`,
`spec:integration`, and `spec:system` tasks, e.g. `bin/rake "spec:unit[--tag ~geo --dry-run]"`.

To run a single test file you can use:

- `bin/rspec spec/controllers/commit_controller_spec.rb` for a rspec test

To run several tests inside one directory:

- `bin/rspec spec/requests/api/` for the rspec tests if you want to test API only

### Speed-up tests, rake tasks, and migrations

[Spring](https://github.com/rails/spring) is a Rails application preloader. It
speeds up development by keeping your application running in the background so
you don't need to boot it every time you run a test, rake task or migration.

If you want to use it, you'll need to export the `ENABLE_SPRING` environment
variable to `1`:

```
export ENABLE_SPRING=1
```

Alternatively you can use the following on each spec run,

```
bundle exec spring rspec some_spec.rb
```

## Compile Frontend Assets

You shouldn't ever need to compile frontend assets manually in development, but
if you ever need to test how the assets get compiled in a production
environment you can do so with the following command:

```
RAILS_ENV=production NODE_ENV=production bundle exec rake gitlab:assets:compile
```

This will compile and minify all JavaScript and CSS assets and copy them along
with all other frontend assets (images, fonts, etc) into `/public/assets` where
they can be easily inspected.

## Updating Emoji Aliases

To update the Emoji aliases file (used for Emoji autocomplete) you must run the
following:

```
bundle exec rake gemojione:aliases
```

## Updating Emoji Digests

To update the Emoji digests file (used for Emoji autocomplete) you must run the
following:

```
bundle exec rake gemojione:digests
```

This will update the file `fixtures/emojis/digests.json` based on the currently
available Emoji.

## Emoji Sprites

Generating a sprite file containing all the Emoji can be done by running:

```
bundle exec rake gemojione:sprite
```

If new emoji are added, the spritesheet may change size. To compensate for
such changes, first generate the `emoji.png` spritesheet with the above Rake
task, then check the dimensions of the new spritesheet and update the
`SPRITESHEET_WIDTH` and `SPRITESHEET_HEIGHT` constants accordingly.

## Updating project templates

Starting a project from a template needs this project to be exported. On a
up to date master branch with run:

```
gdk run
# In a new terminal window
bundle exec rake gitlab:update_project_templates
git checkout -b update-project-templates
git add vendor/project_templates
git commit
git push -u origin update-project-templates
```

Now create a merge request and merge that to master.

## Generate route lists

To see the full list of API routes, you can run:

```shell
bundle exec rake grape:path_helpers
```

For the Rails controllers, run:

```shell
bundle exec rake routes
```

Since these take some time to create, it's often helpful to save the output to
a file for quick reference.

## Show obsolete `ignored_columns`

To see a list of all obsolete `ignored_columns` run:

```
bundle exec rake db:obsolete_ignored_columns
```

Feel free to remove their definitions from their `ignored_columns` definitions.

## Update GraphQL Documentation and Schema definitions

To generate GraphQL documentation based on the GitLab schema, run:

```shell
bundle exec rake gitlab:graphql:compile_docs
```

In its current state, the rake task:

- Generates output for GraphQL objects.
- Places the output at `doc/api/graphql/reference/index.md`.

This uses some features from `graphql-docs` gem like its schema parser and helper methods.
The docs generator code comes from our side giving us more flexibility, like using Haml templates and generating Markdown files.

To edit the template used, please take a look at `lib/gitlab/graphql/docs/templates/default.md.haml`.
The actual renderer is at `Gitlab::Graphql::Docs::Renderer`.

`@parsed_schema` is an instance variable that the `graphql-docs` gem expects to have available.
`Gitlab::Graphql::Docs::Helper` defines the `object` method we currently use. This is also where you
should implement any new methods for new types you'd like to display.

### Update machine-readable schema files

To generate GraphQL schema files based on the GitLab schema, run:

```shell
bundle exec rake gitlab:graphql:schema:dump
```

This uses graphql-ruby's built-in rake tasks to generate files in both [IDL](https://www.prisma.io/blog/graphql-sdl-schema-definition-language-6755bcb9ce51) and JSON formats.
