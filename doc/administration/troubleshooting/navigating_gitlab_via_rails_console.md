---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Navigating GitLab via Rails console **(FREE SELF)**

At the heart of GitLab is a web application [built using the Ruby on Rails
framework](https://about.gitlab.com/blog/2018/10/29/why-we-use-rails-to-build-gitlab/).
Thanks to this, we also get access to the amazing tools built right into Rails.
In this guide, we'll introduce the [Rails console](../operations/rails_console.md#starting-a-rails-console-session)
and the basics of interacting with your GitLab instance from the command line.

WARNING:
The Rails console interacts directly with your GitLab instance. In many cases,
there are no handrails to prevent you from permanently modifying, corrupting
or destroying production data. If you would like to explore the Rails console
with no consequences, you are strongly advised to do so in a test environment.

This guide is targeted at GitLab system administrators who are troubleshooting
a problem or need to retrieve some data that can only be done through direct
access of the GitLab application. Basic knowledge of Ruby is needed (try [this
30-minute tutorial](https://try.ruby-lang.org/) for a quick introduction).
Rails experience is helpful to have but not a must.

## Starting a Rails console session

Your type of GitLab installation determines how
[to start a rails console](../operations/rails_console.md).

The following code examples will all take place inside the Rails console and also
assume an Omnibus GitLab installation.

## Active Record objects

### Looking up database-persisted objects

Under the hood, Rails uses [Active Record](https://guides.rubyonrails.org/active_record_basics.html),
an object-relational mapping system, to read, write and map application objects
to the PostgreSQL database. These mappings are handled by Active Record models,
which are Ruby classes defined in a Rails app. For GitLab, the model classes
can be found at `/opt/gitlab/embedded/service/gitlab-rails/app/models`.

Let's enable debug logging for Active Record so we can see the underlying
database queries made:

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

Now, let's try retrieving a user from the database:

```ruby
user = User.find(1)
```

Which would return:

```ruby
D, [2020-03-05T16:46:25.571238 #910] DEBUG -- :   User Load (1.8ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1
=> #<User id:1 @root>
```

We can see that we've queried the `users` table in the database for a row whose
`id` column has the value `1`, and Active Record has translated that database
record into a Ruby object that we can interact with. Try some of the following:

- `user.username`
- `user.created_at`
- `user.admin`

By convention, column names are directly translated into Ruby object attributes,
so you should be able to do `user.<column_name>` to view the attribute's value.

Also by convention, Active Record class names (singular and in camel case) map
directly onto table names (plural and in snake case) and vice versa. For example,
the `users` table maps to the `User` class, while the `application_settings`
table maps to the `ApplicationSetting` class.

You can find a list of tables and column names in the Rails database schema,
available at `/opt/gitlab/embedded/service/gitlab-rails/db/schema.rb`.

You can also look up an object from the database by attribute name:

```ruby
user = User.find_by(username: 'root')
```

Which would return:

```ruby
D, [2020-03-05T17:03:24.696493 #910] DEBUG -- :   User Load (2.1ms)  SELECT "users".* FROM "users" WHERE "users"."username" = 'root' LIMIT 1
=> #<User id:1 @root>
```

Give the following a try:

- `User.find_by(email: 'admin@example.com')`
- `User.where.not(admin: true)`
- `User.where('created_at < ?', 7.days.ago)`

Did you notice that the last two commands returned an `ActiveRecord::Relation`
object that appeared to contain multiple `User` objects?

Up to now, we've been using `.find` or `.find_by`, which are designed to return
only a single object (notice the `LIMIT 1` in the generated SQL query?).
`.where` is used when it is desirable to get a collection of objects.

Let's get a collection of non-administrator users and see what we can do with it:

```ruby
users = User.where.not(admin: true)
```

Which would return:

```ruby
D, [2020-03-05T17:11:16.845387 #910] DEBUG -- :   User Load (2.8ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE LIMIT 11
=> #<ActiveRecord::Relation [#<User id:3 @support-bot>, #<User id:7 @alert-bot>, #<User id:5 @carrie>, #<User id:4 @bernice>, #<User id:2 @anne>]>
```

Now, try the following:

- `users.count`
- `users.order(created_at: :desc)`
- `users.where(username: 'support-bot')`

In the last command, we see that we can chain `.where` statements to generate
more complex queries. Notice also that while the collection returned contains
only a single object, we cannot directly interact with it:

```ruby
users.where(username: 'support-bot').username
```

Which would return:

```ruby
Traceback (most recent call last):
        1: from (irb):37
D, [2020-03-05T17:18:25.637607 #910] DEBUG -- :   User Load (1.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' LIMIT 11
NoMethodError (undefined method `username' for #<ActiveRecord::Relation [#<User id:3 @support-bot>]>)
Did you mean?  by_username
```

We need to retrieve the single object from the collection by using the `.first`
method to get the first item in the collection:

```ruby
users.where(username: 'support-bot').first.username
```

We now get the result we wanted:

```ruby
D, [2020-03-05T17:18:30.406047 #910] DEBUG -- :   User Load (2.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' ORDER BY "users"."id" ASC LIMIT 1
=> "support-bot"
```

For more on different ways to retrieve data from the database using Active
Record, please see the [Active Record Query Interface documentation](https://guides.rubyonrails.org/active_record_querying.html).

### Modifying Active Record objects

In the previous section, we learned about retrieving database records using
Active Record. Now, we'll learn how to write changes to the database.

First, let's retrieve the `root` user:

```ruby
user = User.find_by(username: 'root')
```

Next, let's try updating the user's password:

```ruby
user.password = 'password'
user.save
```

Which would return:

```ruby
Enqueued ActionMailer::MailDeliveryJob (Job ID: 05915c4e-c849-4e14-80bb-696d5ae22065) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007f42d8ccebe8 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
```

Here, we see that the `.save` command returned `true`, indicating that the
password change was successfully saved to the database.

We also see that the save operation triggered some other action -- in this case
a background job to deliver an email notification. This is an example of an
[Active Record callback](https://guides.rubyonrails.org/active_record_callbacks.html)
-- code which is designated to run in response to events in the Active Record
object life cycle. This is also why using the Rails console is preferred when
direct changes to data is necessary as changes made via direct database queries
will not trigger these callbacks.

It's also possible to update attributes in a single line:

```ruby
user.update(password: 'password')
```

Or update multiple attributes at once:

```ruby
user.update(password: 'password', email: 'hunter2@example.com')
```

Now, let's try something different:

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save
```

This returns `false`, indicating that the changes we made were not saved to the
database. You can probably guess why, but let's find out for sure:

```ruby
user.save!
```

This should return:

```ruby
Traceback (most recent call last):
        1: from (irb):64
ActiveRecord::RecordInvalid (Validation failed: Password confirmation doesn't match Password)
```

Aha! We've tripped an [Active Record Validation](https://guides.rubyonrails.org/active_record_validations.html).
Validations are business logic put in place at the application-level to prevent
unwanted data from being saved to the database and in most cases come with
helpful messages letting you know how to fix the problem inputs.

We can also add the bang (Ruby speak for `!`) to `.update`:

```ruby
user.update!(password: 'password', password_confirmation: 'hunter2')
```

In Ruby, method names ending with `!` are commonly known as "bang methods". By
convention, the bang indicates that the method directly modifies the object it
is acting on, as opposed to returning the transformed result and leaving the
underlying object untouched. For Active Record methods that write to the
database, bang methods also serve an additional function: they raise an
explicit exception whenever an error occurs, instead of just returning `false`.

We can also skip validations entirely:

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save!(validate: false)
```

This is not recommended, as validations are usually put in place to ensure the
integrity and consistency of user-provided data.

Note that a validation error will prevent the entire object from being saved to
the database. We'll see a little of this in the next section. If you're getting
a mysterious red banner in the GitLab UI when submitting a form, this can often
be the fastest way to get to the root of the problem.

### Interacting with Active Record objects

At the end of the day, Active Record objects are just normal Ruby objects. As
such, we can define methods on them which perform arbitrary actions.

For example, GitLab developers have added some methods which help with
two-factor authentication:

```ruby
def disable_two_factor!
  transaction do
    update(
      otp_required_for_login:      false,
      encrypted_otp_secret:        nil,
      encrypted_otp_secret_iv:     nil,
      encrypted_otp_secret_salt:   nil,
      otp_grace_period_started_at: nil,
      otp_backup_codes:            nil
    )
    self.u2f_registrations.destroy_all # rubocop: disable DestroyAll
  end
end

def two_factor_enabled?
  two_factor_otp_enabled? || two_factor_u2f_enabled?
end
```

(See: `/opt/gitlab/embedded/service/gitlab-rails/app/models/user.rb`)

We can then use these methods on any user object:

```ruby
user = User.find_by(username: 'root')
user.two_factor_enabled?
user.disable_two_factor!
```

Some methods are defined by gems, or Ruby software packages, which GitLab uses.
For example, the [StateMachines](https://github.com/state-machines/state_machines-activerecord)
gem which GitLab uses to manage user state:

```ruby
state_machine :state, initial: :active do
  event :block do

  ...

  event :activate do

  ...

end
```

Give it a try:

```ruby
user = User.find_by(username: 'root')
user.state
user.block
user.state
user.activate
user.state
```

Earlier, we mentioned that a validation error will prevent the entire object
from being saved to the database. Let's see how this can have unexpected
interactions:

```ruby
user.password = 'password'
user.password_confirmation = 'hunter2'
user.block
```

We get `false` returned! Let's find out what happened by adding a bang as we did
earlier:

```ruby
user.block!
```

Which would return:

```ruby
Traceback (most recent call last):
        1: from (irb):87
StateMachines::InvalidTransition (Cannot transition state via :block from :active (Reason(s): Password confirmation doesn't match Password))
```

We see that a validation error from what feels like a completely separate
attribute comes back to haunt us when we try to update the user in any way.

In practical terms, we sometimes see this happen with GitLab administration settings --
validations are sometimes added or changed in a GitLab update, resulting in
previously saved settings now failing validation. Because you can only update
a subset of settings at once through the UI, in this case the only way to get
back to a good state is direct manipulation via Rails console.

### Commonly used Active Record models and how to look up objects

**Get a user by primary email address or username:**

```ruby
User.find_by(email: 'admin@example.com')
User.find_by(username: 'root')
```

**Get a user by primary OR secondary email address:**

```ruby
User.find_by_any_email('user@example.com')
```

The `find_by_any_email` method is a custom method added by GitLab developers rather
than a Rails-provided default method.

**Get a collection of administrator users:**

```ruby
User.admins
```

`admins` is a [scope convenience method](https://guides.rubyonrails.org/active_record_querying.html#scopes)
which does `where(admin: true)` under the hood.

**Get a project by its path:**

```ruby
Project.find_by_full_path('group/subgroup/project')
```

`find_by_full_path` is a custom method added by GitLab developers rather
than a Rails-provided default method.

**Get a project's issue or merge request by its numeric ID:**

```ruby
project = Project.find_by_full_path('group/subgroup/project')
project.issues.find_by(iid: 42)
project.merge_requests.find_by(iid: 42)
```

`iid` means "internal ID" and is how we keep issue and merge request IDs
scoped to each GitLab project.

**Get a group by its path:**

```ruby
Group.find_by_full_path('group/subgroup')
```

**Get a group's related groups:**

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get a group's parent group
group.parent

# Get a group's child groups
group.children
```

**Get a group's projects:**

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get group's immediate child projects
group.projects

# Get group's child projects, including those in subgroups
group.all_projects
```

**Get CI pipeline or builds:**

```ruby
Ci::Pipeline.find(4151)
Ci::Build.find(66124)
```

The pipeline and job ID numbers increment globally across your GitLab
instance, so there's no need to use an internal ID attribute to look them up,
unlike with issues or merge requests.

**Get the current application settings object:**

```ruby
ApplicationSetting.current
```
