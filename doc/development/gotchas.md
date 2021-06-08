---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Gotchas

The purpose of this guide is to document potential "gotchas" that contributors
might encounter or should avoid during development of GitLab CE and EE.

## Do not read files from app/assets directory

In GitLab 10.8 and later, Omnibus has [dropped the `app/assets` directory](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2456),
after asset compilation. The `ee/app/assets`, `vendor/assets` directories are dropped as well.

This means that reading files from that directory fails in Omnibus-installed GitLab instances:

```ruby
file = Rails.root.join('app/assets/images/logo.svg')

# This file does not exist, read will fail with:
# Errno::ENOENT: No such file or directory @ rb_sysopen
File.read(file)
```

## Do not assert against the absolute value of a sequence-generated attribute

Consider the following factory:

```ruby
FactoryBot.define do
  factory :label do
    sequence(:title) { |n| "label#{n}" }
  end
end
```

Consider the following API spec:

```ruby
require 'spec_helper'

RSpec.describe API::Labels do
  it 'creates a first label' do
    create(:label)

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first['name']).to eq('label1')
  end

  it 'creates a second label' do
    create(:label)

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first['name']).to eq('label1')
  end
end
```

When run, this spec doesn't do what we might expect:

```shell
1) API::API reproduce sequence issue creates a second label
   Failure/Error: expect(json_response.first['name']).to eq('label1')

     expected: "label1"
          got: "label2"

     (compared using ==)
```

This is because FactoryBot sequences are not reset for each example.

Please remember that sequence-generated values exist only to avoid having to
explicitly set attributes that have a uniqueness constraint when using a factory.

### Solution

If you assert against a sequence-generated attribute's value, you should set it
explicitly. Also, the value you set shouldn't match the sequence pattern.

For instance, using our `:label` factory, writing `create(:label, title: 'foo')`
is ok, but `create(:label, title: 'label1')` is not.

Following is the fixed API spec:

```ruby
require 'spec_helper'

RSpec.describe API::Labels do
  it 'creates a first label' do
    create(:label, title: 'foo')

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first['name']).to eq('foo')
  end

  it 'creates a second label' do
    create(:label, title: 'bar')

    get api("/projects/#{project.id}/labels", user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.first['name']).to eq('bar')
  end
end
```

## Avoid using `expect_any_instance_of` or `allow_any_instance_of` in RSpec

### Why

- Because it is not isolated therefore it might be broken at times.
- Because it doesn't work whenever the method we want to stub was defined
  in a prepended module, which is very likely the case in EE. We could see
  error like this:

  ```plaintext
  1.1) Failure/Error: expect_any_instance_of(ApplicationSetting).to receive_messages(messages)
       Using `any_instance` to stub a method (elasticsearch_indexing) that has been defined on a prepended module (EE::ApplicationSetting) is not supported.
  ```

### Alternative: `expect_next_instance_of`, `allow_next_instance_of`, `expect_next_found_instance_of` or `allow_next_found_instance_of`

Instead of writing:

```ruby
# Don't do this:
expect_any_instance_of(Project).to receive(:add_import_job)

# Don't do this:
allow_any_instance_of(Project).to receive(:add_import_job)
```

We could write:

```ruby
# Do this:
expect_next_instance_of(Project) do |project|
  expect(project).to receive(:add_import_job)
end

# Do this:
allow_next_instance_of(Project) do |project|
  allow(project).to receive(:add_import_job)
end

# Do this:
expect_next_found_instance_of(Project) do |project|
  expect(project).to receive(:add_import_job)
end

# Do this:
allow_next_found_instance_of(Project) do |project|
  allow(project).to receive(:add_import_job)
end
```

Since Active Record is not calling the `.new` method on model classes to instantiate the objects,
you should use `expect_next_found_instance_of` or `allow_next_found_instance_of` mock helpers to setup mock on objects returned by Active Record query & finder methods._

If we also want to initialize the instance with some particular arguments, we
could also pass it like:

```ruby
# Do this:
expect_next_instance_of(MergeRequests::RefreshService, project, user) do |refresh_service|
  expect(refresh_service).to receive(:execute).with(oldrev, newrev, ref)
end
```

This would expect the following:

```ruby
# Above expects:
refresh_service = MergeRequests::RefreshService.new(project, user)
refresh_service.execute(oldrev, newrev, ref)
```

## Do not `rescue Exception`

See ["Why is it bad style to `rescue Exception => e` in Ruby?"](https://stackoverflow.com/questions/10048173/why-is-it-bad-style-to-rescue-exception-e-in-ruby).

This rule is [enforced automatically by
RuboCop](https://gitlab.com/gitlab-org/gitlab-foss/blob/8-4-stable/.rubocop.yml#L911-914)._

## Do not use inline JavaScript in views

Using the inline `:javascript` Haml filters comes with a
performance overhead. Using inline JavaScript is not a good way to structure your code and should be avoided.

We've [removed these two filters](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/hamlit.rb)
in an initializer.

### Further reading

- Stack Overflow: [Why you should not write inline JavaScript](https://softwareengineering.stackexchange.com/questions/86589/why-should-i-avoid-inline-scripting)

## Auto loading

Rails auto-loading on `development` differs from the load policy in the `production` environment.
In development mode, `config.eager_load` is set to `false`, which means classes
are loaded as needed. With the classic Rails autoloader, it is known that this can lead to
[Rails resolving the wrong class](https://guides.rubyonrails.org/v5.2/autoloading_and_reloading_constants.html#when-constants-aren-t-missed-relative-references)
if the class name is ambiguous. This can be fixed by specifying the complete namespace to the class.

### Error prone example

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  ...
end

# app/controllers/projects/application_controller.rb
class Projects::ApplicationController < ApplicationController
  ...
  private

  def project
    ...
  end
end

# app/controllers/projects/submodule/some_controller.rb
module Projects
  module Submodule
    class SomeController < ApplicationController
      def index
        @some_id = project.id
      end
    end
  end
end
```

In this case, if for any reason the top level `ApplicationController`
is loaded but `Projects::ApplicationController` is not, `ApplicationController`
would be resolved to `::ApplicationController` and then the `project` method is
undefined, causing an error.

#### Solution

```ruby
# app/controllers/projects/submodule/some_controller.rb
module Projects
  module Submodule
    class SomeController < Projects::ApplicationController
      def index
        @some_id = project.id
      end
    end
  end
end
```

By specifying `Projects::`, we tell Rails exactly what class we are referring
to and we would avoid the issue.

NOTE:
This problem disappears as soon as we upgrade to Rails 6 and use the Zeitwerk autoloader.

### Further reading

- Rails Guides: [Autoloading and Reloading Constants (Classic Mode)](https://guides.rubyonrails.org/autoloading_and_reloading_constants_classic_mode.html)
- Ruby Constant lookup: [Everything you ever wanted to know about constant lookup in Ruby](https://cirw.in/blog/constant-lookup)
- Rails 6 and Zeitwerk autoloader: [Understanding Zeitwerk in Rails 6](https://medium.com/cedarcode/understanding-zeitwerk-in-rails-6-f168a9f09a1f)

## Storing assets that do not require pre-compiling

Assets that need to be served to the user are stored under the `app/assets` directory, which is later pre-compiled and placed in the `public/` directory.

However, you cannot access the content of any file from within `app/assets` from the application code, as we do not include that folder in production installations as a [space saving measure](https://gitlab.com/gitlab-org/omnibus-gitlab/-/commit/ca049f990b223f5e1e412830510a7516222810be).

```ruby
support_bot = User.support_bot

# accessing a file from the `app/assets` folder
support_bot.avatar = Rails.root.join('app', 'assets', 'images', 'bot_avatars', 'support_bot.png').open

support_bot.save!
```

While the code above works in local environments, it errors out in production installations as the `app/assets` folder is not included.

### Solution

The alternative is the `lib/assets` folder. Use it if you need to add assets (like images) to the repository that meet the following conditions:

- The assets do not need to be directly served to the user (and hence need not be pre-compiled).
- The assets do need to be accessed via application code.

In short:

Use `app/assets` for storing any asset that needs to be precompiled and served to the end user.
Use `lib/assets` for storing any asset that does not need to be served to the end user directly, but is still required to be accessed by the application code.

MR for reference: [!37671](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37671)
