# Database Debugging and Troubleshooting

This section is to help give some copy-pasta you can use as a reference when you
run into some head-banging database problems.

An easy first step is to search for your error in Slack or google "GitLab <my error>".

---

Available `RAILS_ENV`

 - `development` (this is your main GDK db)
 - `test` (used for tests like rspec and spinach)


## Nuke everything and start over

If you just want to delete everything and start over,

 - `bundle exec rake dev:setup RAILS_ENV=development` : Also runs DB specific stuff and seeds dummy data (slow)
 - `bundle exec rake db:reset RAILS_ENV=development` : Doesn't do the above (fast)
 - `bundle exec rake db:reset RAILS_ENV=test` : Fix the test DB, since it doesn't contain important data.

## Migration wrangling

 - `bundle exec rake db:migrate RAILS_ENV=development`: Execute any pending migrations that you may have picked up from a MR
 - `bundle exec rake db:migrate:status RAILS_ENV=development`: Check if all migrations are `up` or `down`
 - `bundle exec rake db:migrate:down VERSION=20170926203418 RAILS_ENV=development`: Tear down a migration
 - `bundle exec rake db:migrate:up VERSION=20170926203418 RAILS_ENV=development`: Setup a migration
 - `bundle exec rake db:migrate:redo VERSION=20170926203418 RAILS_ENV=development`: Re-run a specific migration


## Manually access the database

Access the database via one of these commands (they all get you to the same place)

```
gdk psql -d gitlabhq_development
bundle exec rails dbconsole RAILS_ENV=development
bundle exec rails db RAILS_ENV=development
```

 - `\q`: Quit/exit
 - `\dt`: List all tables
 - `\d+ issues`: List columns for `issues` table
 - `CREATE TABLE board_labels();`: Create a table called `board_labels`
 - `SELECT * FROM schema_migrations WHERE version = '20170926203418';`: Check if a migration was run
 - `DELETE FROM schema_migrations WHERE version = '20170926203418';`: Manually remove a migration
