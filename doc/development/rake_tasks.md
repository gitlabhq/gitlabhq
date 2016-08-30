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
- `rake teaspoon` to run the teaspoon test suite
- `rake gitlab:test` to run all the tests

Note: Both `rake spinach` and `rake spec` takes significant time to pass. 
Instead of running full test suite locally you can save a lot of time by running
a single test or directory related to your changes. After you submit merge request 
CI will run full test suite for you. Green CI status in the merge request means 
full test suite is passed.  

Note: You can't run `rspec .` since this will try to run all the `_spec.rb`
files it can find, also the ones in `/tmp`

To run a single test file you can use:

- `bundle exec rspec spec/controllers/commit_controller_spec.rb` for a rspec test
- `bundle exec spinach features/project/issues/milestones.feature` for a spinach test

To run several tests inside one directory:

- `bundle exec rspec spec/requests/api/` for the rspec tests if you want to test API only
- `bundle exec spinach features/profile/` for the spinach tests if you want to test only profile pages

If you want to use [Spring](https://github.com/rails/spring) set
`ENABLE_SPRING=1` in your environment.

## Generate searchable docs for source code

You can find results under the `doc/code` directory.

```
bundle exec rake gitlab:generate_docs
```

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
