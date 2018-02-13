# Query Count Limits

Each controller or API endpoint is allowed to execute up to 100 SQL queries and
in test environments we'll raise an error when this threshold is exceeded.

## Solving Failing Tests

When a test fails because it executes more than 100 SQL queries there are two
solutions to this problem:

1. Reduce the number of SQL queries that are executed.
2. Whitelist the controller or API endpoint.

You should only resort to whitelisting when an existing controller or endpoint
is to blame as in this case reducing the number of SQL queries can take a lot of
effort. Newly added controllers and endpoints are not allowed to execute more
than 100 SQL queries and no exceptions will be made for this rule. _If_ a large
number of SQL queries is necessary to perform certain work it's best to have
this work performed by Sidekiq instead of doing this directly in a web request.

## Whitelisting

In the event that you _have_ to whitelist a controller you'll first need to
create an issue. This issue should (preferably in the title) mention the
controller or endpoint and include the appropriate labels (`database`,
`performance`, and at least a team specific label such as `Discussion`).

Once the issue has been created you can whitelist the code in question. For
Rails controllers it's best to create a `before_action` hook that runs as early
as possible. The called method in turn should call
`Gitlab::QueryLimiting.whitelist('issue URL here')`. For example:

```ruby
class MyController < ApplicationController
  before_action :whitelist_query_limiting, only: [:show]

  def index
    # ...
  end

  def show
    # ...
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/...')
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
  Gitlab::QueryLimiting.whitelist('...')

  # ...
end
```
