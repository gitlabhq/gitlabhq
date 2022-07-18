---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Debugging tips **(FREE SELF)**

Sometimes things don't work the way they should. Here are some tips on debugging issues out
in production.

## Starting a Rails console session

Troubleshooting and debugging your GitLab instance often requires a Rails console.

Your type of GitLab installation determines how
[to start a rails console](../operations/rails_console.md).
See also:

- [GitLab Rails Console Cheat Sheet](gitlab_rails_cheat_sheet.md).

### Enabling Active Record logging

You can enable output of Active Record debug logging in the Rails console
session by running:

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

This shows information about database queries triggered by any Ruby code
you may run in the console. To turn off logging again, run:

```ruby
ActiveRecord::Base.logger = nil
```

### Disabling database statement timeout

You can disable the PostgreSQL statement timeout for the current Rails console
session by running:

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

This change only affects the current Rails console session and is
not persisted in the GitLab production environment or in the next Rails
console session.

### Output Rails console session history

If you'd like to output your Rails console command history in a format that's
easy to copy and save for future reference, you can run:

```ruby
puts Readline::HISTORY.to_a
```

## Using the Rails runner

If you need to run some Ruby code in the context of your GitLab production
environment, you can do so using the [Rails runner](https://guides.rubyonrails.org/command_line.html#rails-runner). When executing a script file, the script must be accessible by the `git` user.

**For Omnibus installations**

```shell
sudo gitlab-rails runner "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo gitlab-rails runner "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo gitlab-rails runner /path/to/script.rb
```

**For installations from source**

```shell
sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
```

## More information

- [Debugging Stuck Ruby Processes](https://newrelic.com/blog/best-practices/debugging-stuck-ruby-processes-what-to-do-before-you-kill-9)
