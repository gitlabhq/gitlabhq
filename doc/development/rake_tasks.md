# Rake tasks for developers

## Setup db with developer seeds

Note that if your db user does not have advanced privileges you must create the db manually before running this command.

```
bundle exec rake setup
```

The `setup` task is a alias for `gitlab:setup`.
This tasks calls `db:reset` to create the database, calls `add_limits_mysql` that adds limits to the database schema in case of a MySQL database and finally it calls `db:seed_fu` to seed the database.
Note: `db:setup` calls `db:seed` but this does nothing.

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
