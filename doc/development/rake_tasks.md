# Rake tasks for developers

## Setup db with developer seeds

Note that if your db user does not have advanced privileges you must create the db manually before running this command.

```
bundle exec rake setup
```

The `setup` task is an alias for `gitlab:setup`.
This tasks calls `db:reset` to create the database, calls `add_limits_mysql` that adds limits to the database schema in case of a MySQL database and finally it calls `db:seed_fu` to seed the database.
Note: `db:setup` calls `db:seed` but this does nothing.

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

### Notes for MySQL

Since the seeds would contain various UTF-8 characters, such as emojis or so,
we'll need to make sure that we're using `utf8mb4` for all the encoding
settings and `utf8mb4_unicode_ci` for collation. Please check
[MySQL utf8mb4 support](../install/database_mysql.md#mysql-utf8mb4-support)

Make sure that `config/database.yml` has `encoding: utf8mb4`, too.

Next, we'll need to update the schema to make the indices fit:

``` shell
sed -i 's/limit: 255/limit: 191/g' db/schema.rb
```

Then run the setup script:

``` shell
bundle exec rake setup
```

To make sure that indices still fit. You could find great details in:
[How to support full Unicode in MySQL databases](https://mathiasbynens.be/notes/mysql-utf8mb4)

## Run tests

In order to run the test you can use the following commands:
- `rake spinach` to run the spinach suite
- `rake spec` to run the rspec suite
- `rake karma` to run the karma test suite
- `rake gitlab:test` to run all the tests

Note: Both `rake spinach` and `rake spec` takes significant time to pass.
Instead of running full test suite locally you can save a lot of time by running
a single test or directory related to your changes. After you submit merge request
CI will run full test suite for you. Green CI status in the merge request means
full test suite is passed.

Note: You can't run `rspec .` since this will try to run all the `_spec.rb`
files it can find, also the ones in `/tmp`

To run a single test file you can use:

- `bin/rspec spec/controllers/commit_controller_spec.rb` for a rspec test
- `bin/spinach features/project/issues/milestones.feature` for a spinach test

To run several tests inside one directory:

- `bin/rspec spec/requests/api/` for the rspec tests if you want to test API only
- `bin/spinach features/profile/` for the spinach tests if you want to test only profile pages

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

## Generate API documentation for project services (e.g. Slack)

```
bundle exec rake services:doc
```

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
