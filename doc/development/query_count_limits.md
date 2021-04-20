---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Query Count Limits

Each controller or API endpoint is allowed to execute up to 100 SQL queries and
in test environments we raise an error when this threshold is exceeded.

## Solving Failing Tests

When a test fails because it executes more than 100 SQL queries there are two
solutions to this problem:

- Reduce the number of SQL queries that are executed.
- Disable query limiting for the controller or API endpoint.

You should only resort to disabling query limits when an existing controller or endpoint
is to blame as in this case reducing the number of SQL queries can take a lot of
effort. Newly added controllers and endpoints are not allowed to execute more
than 100 SQL queries and no exceptions are made for this rule. _If_ a large
number of SQL queries is necessary to perform certain work it's best to have
this work performed by Sidekiq instead of doing this directly in a web request.

## Disable query limiting

In the event that you _have_ to disable query limits for a controller, you must first
create an issue. This issue should (preferably in the title) mention the
controller or endpoint and include the appropriate labels (`database`,
`performance`, and at least a team specific label such as `Discussion`).

After the issue has been created, you can disable query limits on the code in question. For
Rails controllers it's best to create a `before_action` hook that runs as early
as possible. The called method in turn should call
`Gitlab::QueryLimiting.disable!('issue URL here')`. For example:

```ruby
class MyController < ApplicationController
  before_action :disable_query_limiting, only: [:show]

  def index
    # ...
  end

  def show
    # ...
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/...')
  end
end
```

By using a `before_action` you don't have to modify the controller method in
question, reducing the likelihood of merge conflicts.

For Grape API endpoints there unfortunately is not a reliable way of running a
hook before a specific endpoint. This means that you have to add the whitelist
call directly into the endpoint like so:

```ruby
get '/projects/:id/foo' do
  Gitlab::QueryLimiting.disable!('...')

  # ...
end
```
