---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# API style guide

This style guide recommends best practices for API development.

## Instance variables

Please do not use instance variables, there is no need for them (we don't need
to access them as we do in Rails views), local variables are fine.

## Entities

Always use an [Entity](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/entities) to present the endpoint's payload.

## Documentation

Each new or updated API endpoint must come with documentation, unless it is internal or behind a feature flag.
The docs should be in the same merge request, or, if strictly necessary,
in a follow-up with the same milestone as the original merge request.

See the [Documentation Style Guide RESTful API page](documentation/restful_api_styleguide.md) for details on documenting API resources in Markdown as well as in OpenAPI definition files.

## Methods and parameters description

Every method must be described using the [Grape DSL](https://github.com/ruby-grape/grape#describing-methods)
(see [`environments.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/environments.rb)
for a good example):

- `desc` for the method summary. You should pass it a block for additional
  details such as:
  - The GitLab version when the endpoint was added. If it is behind a feature flag, mention that instead: _This feature is gated by the :feature\_flag\_symbol feature flag._
  - If the endpoint is deprecated, and if so, its planned removal date

- `params` for the method parameters. This acts as description,
  [validation, and coercion of the parameters](https://github.com/ruby-grape/grape#parameter-validation-and-coercion)

A good example is as follows:

```ruby
desc 'Get all broadcast messages' do
  detail 'This feature was introduced in GitLab 8.12.'
  success Entities::BroadcastMessage
end
params do
  optional :page,     type: Integer, desc: 'Current page number'
  optional :per_page, type: Integer, desc: 'Number of messages per page'
end
get do
  messages = BroadcastMessage.all

  present paginate(messages), with: Entities::BroadcastMessage
end
```

## Declared parameters

> Grape allows you to access only the parameters that have been declared by your
`params` block. It filters out the parameters that have been passed, but are not
allowed.

– <https://github.com/ruby-grape/grape#declared>

### Exclude parameters from parent namespaces

> By default `declared(params)`includes parameters that were defined in all
parent namespaces.

– <https://github.com/ruby-grape/grape#include-parent-namespaces>

In most cases you should exclude parameters from the parent namespaces:

```ruby
declared(params, include_parent_namespaces: false)
```

### When to use `declared(params)`

You should always use `declared(params)` when you pass the parameters hash as
arguments to a method call.

For instance:

```ruby
# bad
User.create(params) # imagine the user submitted `admin=1`... :)

# good
User.create(declared(params, include_parent_namespaces: false).to_h)
```

NOTE:
`declared(params)` return a `Hashie::Mash` object, on which you must
call `.to_h`.

But we can use `params[key]` directly when we access single elements.

For instance:

```ruby
# good
Model.create(foo: params[:foo])
```

## Array types

With Grape v1.3+, Array types must be defined with a `coerce_with`
block, or parameters, fails to validate when passed a string from an
API request. See the [Grape upgrading
documentation](https://github.com/ruby-grape/grape/blob/master/UPGRADING.md#ensure-that-array-types-have-explicit-coercions)
for more details.

### Automatic coercion of nil inputs

Prior to Grape v1.3.3, Array parameters with `nil` values would
automatically be coerced to an empty Array. However, due to [this pull
request in v1.3.3](https://github.com/ruby-grape/grape/pull/2040), this
is no longer the case. For example, suppose you define a PUT `/test`
request that has an optional parameter:

```ruby
optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The user ids for this rule'
```

Normally, a request to PUT `/test?user_ids` would cause Grape to pass
`params` of `{ user_ids: nil }`.

This may introduce errors with endpoints that expect a blank array and
do not handle `nil` inputs properly. To preserve the previous behavior,
there is a helper method `coerce_nil_params_to_array!` that is used
in the `before` block of all API calls:

```ruby
before do
  coerce_nil_params_to_array!
end
```

With this change, a request to PUT `/test?user_ids` causes Grape to
pass `params` to be `{ user_ids: [] }`.

There is [an open issue in the Grape tracker](https://github.com/ruby-grape/grape/issues/2068)
to make this easier.

## Using HTTP status helpers

For non-200 HTTP responses, use the provided helpers in `lib/api/helpers.rb` to ensure correct behavior (`not_found!`, `no_content!` etc.). These `throw` inside Grape and abort the execution of your endpoint.

For `DELETE` requests, you should also generally use the `destroy_conditionally!` helper which by default returns a `204 No Content` response on success, or a `412 Precondition Failed` response if the given `If-Unmodified-Since` header is out of range. This helper calls `#destroy` on the passed resource, but you can also implement a custom deletion method by passing a block.

## Using API path helpers in GitLab Rails codebase

Because we support [installing GitLab under a relative URL](../install/relative_url.md), one must take this
into account when using API path helpers generated by Grape. Any such API path
helper usage must be in wrapped into the `expose_path` helper call.

For instance:

```haml
- endpoint = expose_path(api_v4_projects_issues_related_merge_requests_path(id: @project.id, issue_iid: @issue.iid))
```

## Custom Validators

In order to validate some parameters in the API request, we validate them
before sending them further (say Gitaly). The following are the
[custom validators](https://GitLab.com/gitlab-org/gitlab/-/tree/master/lib/api/validations/validators),
which we have added so far and how to use them. We also wrote a
guide on how you can add a new custom validator.

### Using custom validators

- `FilePath`:

  GitLab supports various functionalities where we need to traverse a file path.
  The [`FilePath` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/file_path.rb)
  validates the parameter value for different cases. Mainly, it checks whether a
  path is relative and does it contain `../../` relative traversal using
  `File::Separator` or not, and whether the path is absolute, for example
  `/etc/passwd/`. By default, absolute paths are not allowed. However, you can optionally pass in an allowlist for allowed absolute paths in the following way:
  `requires :file_path, type: String, file_path: { allowlist: ['/foo/bar/', '/home/foo/', '/app/home'] }`

- `Git SHA`:

  The [`Git SHA` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/git_sha.rb)
  checks whether the Git SHA parameter is a valid SHA.
  It checks by using the regex mentioned in [`commit.rb`](https://gitlab.com/gitlab-org/gitlab/-/commit/b9857d8b662a2dbbf54f46ecdcecb44702affe55#d1c10892daedb4d4dd3d4b12b6d071091eea83df_30_30) file.

- `Absence`:

  The [`Absence` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/absence.rb)
  checks whether a particular parameter is absent in a given parameters hash.

- `IntegerNoneAny`:

  The [`IntegerNoneAny` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/integer_none_any.rb)
  checks if the value of the given parameter is either an `Integer`, `None`, or `Any`.
  It allows only either of these mentioned values to move forward in the request.

- `ArrayNoneAny`:

  The [`ArrayNoneAny` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/array_none_any.rb)
  checks if the value of the given parameter is either an `Array`, `None`, or `Any`.
  It allows only either of these mentioned values to move forward in the request.

- `EmailOrEmailList`:

  The [`EmailOrEmailList` validator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators/email_or_email_list.rb)
  checks if the value of a string or a list of strings contains only valid
  email addresses. It allows only lists with all valid email addresses to move forward in the request.

### Adding a new custom validator

Custom validators are a great way to validate parameters before sending
them to platform for further processing. It saves some back-and-forth
from the server to the platform if we identify invalid parameters at the beginning.

If you need to add a custom validator, it would be added to
it's own file in the [`validators`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/validations/validators) directory.
Since we use [Grape](https://github.com/ruby-grape/grape) to add our API
we inherit from the `Grape::Validations::Base` class in our validator class.
Now, all you have to do is define the `validate_param!` method which takes
in two parameters: the `params` hash and the `param` name to validate.

The body of the method does the hard work of validating the parameter value
and returns appropriate error messages to the caller method.

Lastly, we register the validator using the line below:

```ruby
Grape::Validations.register_validator(<validator name as symbol>, ::API::Helpers::CustomValidators::<YourCustomValidatorClassName>)
```

Once you add the validator, make sure you add the `rspec`s for it into
it's own file in the [`validators`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/api/validations/validators) directory.

## Internal API

The [internal API](internal_api.md) is documented for internal use. Please keep it up to date so we know what endpoints
different components are making use of.

## Avoiding N+1 problems

In order to avoid N+1 problems that are common when returning collections
of records in an API endpoint, we should use eager loading.

A standard way to do this within the API is for models to implement a
scope called `with_api_entity_associations` that preloads the
associations and data returned in the API. An example of this scope can
be seen in
[the `Issue` model](https://gitlab.com/gitlab-org/gitlab/-/blob/2fedc47b97837ea08c3016cf2fb773a0300a4a25/app%2Fmodels%2Fissue.rb#L62).

In situations where the same model has multiple entities in the API
(for instance, `UserBasic`, `User` and `UserPublic`) you should use your
discretion with applying this scope. It may be that you optimize for the
most basic entity, with successive entities building upon that scope.

The `with_api_entity_associations` scope also [automatically preloads
data](https://gitlab.com/gitlab-org/gitlab/-/blob/19f74903240e209736c7668132e6a5a735954e7c/app%2Fmodels%2Ftodo.rb#L34)
for `Todo` _targets_ when returned in the [to-dos API](../api/todos.md).

For more context and discussion about preloading see
[this merge request](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25711)
which introduced the scope.

### Verifying with tests

When an API endpoint returns collections, always add a test to verify
that the API endpoint does not have an N+1 problem, now and in the future.
We can do this using [`ActiveRecord::QueryRecorder`](query_recorder.md).

Example:

```ruby
def make_api_request
  get api('/foo', personal_access_token: pat)
end

it 'avoids N+1 queries', :request_store do
  # Firstly, record how many PostgreSQL queries the endpoint will make
  # when it returns a single record
  create_record

  control = ActiveRecord::QueryRecorder.new { make_api_request }

  # Now create a second record and ensure that the API does not execute
  # any more queries than before
  create_record

  expect { make_api_request }.not_to exceed_query_limit(control)
end
```

## Testing

When writing tests for new API endpoints, consider using a schema [fixture](testing_guide/best_practices.md#fixtures) located in `/spec/fixtures/api/schemas`. You can `expect` a response to match a given schema:

```ruby
expect(response).to match_response_schema('merge_requests')
```

Also see [verifying N+1 performance](#verifying-with-tests) in tests.

## Include a changelog entry

All client-facing changes **must** include a [changelog entry](changelog.md).
This does not include internal APIs.
