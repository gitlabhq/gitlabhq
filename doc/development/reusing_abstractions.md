---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Guidelines for reusing abstractions
---

As GitLab has grown, different patterns emerged across the codebase. Service
classes, serializers, and presenters are just a few. These patterns made it easy
to reuse code, but at the same time make it easy to accidentally reuse the wrong
abstraction in a particular place.

## Why these guidelines are necessary

Code reuse is good, but sometimes this can lead to shoehorning the wrong
abstraction into a particular use case. This in turn can have a negative impact
on maintainability, the ability to easily debug problems, or even performance.

An example would be to use `ProjectsFinder` in `IssuesFinder` to limit issues to
those belonging to a set of projects. While initially this may seem like a good
idea, both classes provide a very high level interface with very little control.
This means that `IssuesFinder` may not be able to produce a better optimized
database query, as a large portion of the query is controlled by the internals
of `ProjectsFinder`.

To work around this problem, you would use the same code used by
`ProjectsFinder`, instead of using `ProjectsFinder` itself directly. This allows
you to compose your behavior better, giving you more control over the behavior
of the code.

To illustrate, consider the following code from `IssuableFinder#projects`:

```ruby
return @projects = project if project?

projects =
  if current_user && params[:authorized_only].presence && !current_user_related?
    current_user.authorized_projects
  elsif group
    finder_options = { include_subgroups: params[:include_subgroups], exclude_shared: true }
    GroupProjectsFinder.new(group: group, current_user: current_user, options: finder_options).execute
  else
    ProjectsFinder.new(current_user: current_user).execute
  end

@projects = projects.with_feature_available_for_user(klass, current_user).reorder(nil)
```

Here we determine what projects to scope our data to, using three different
approaches. When a group is specified, we use `GroupProjectsFinder` to retrieve
all the projects of that group. On the surface this seems harmless: it is easy
to use, and we only need two lines of code.

In reality, things can get hairy very quickly. For example, the query produced
by `GroupProjectsFinder` may start out simple. Over time more and more
functionality is added to this (high level) interface. Instead of _only_
affecting the cases where this is necessary, it may also start affecting
`IssuableFinder` in a negative way. For example, the query produced by
`GroupProjectsFinder` may include unnecessary conditions. Since we're using a
finder here, we can't easily opt-out of that behavior. We could add options to
do so, but then we'd need as many options as we have features. Every option adds
two code paths, which means that for four features we have to cover 8 different
code paths.

A much more reliable (and pleasant) way of dealing with this, is to use
the underlying bits that make up `GroupProjectsFinder` directly. This means we
may need a little bit more code in `IssuableFinder`, but it also gives us much
more control and certainty. This means we might end up with something like this:

```ruby
return @projects = project if project?

projects =
  if current_user && params[:authorized_only].presence && !current_user_related?
    current_user.authorized_projects
  elsif group
    current_user
      .owned_groups(subgroups: params[:include_subgroups])
      .projects
      .any_additional_method_calls
      .that_might_be_necessary
  else
    current_user
      .projects_visible_to_user
      .any_additional_method_calls
      .that_might_be_necessary
  end

@projects = projects.with_feature_available_for_user(klass, current_user).reorder(nil)
```

This is just a sketch, but it shows the general idea: we would use whatever the
`GroupProjectsFinder` and `ProjectsFinder` finders use under the hoods.

## End goal

The guidelines in this document are meant to foster _better_ code reuse, by
clearly defining what can be reused where, and what to do when you cannot reuse
something. Clearly separating abstractions makes it harder to use the wrong one,
makes it easier to debug the code, and (hopefully) results in fewer performance
problems.

## Abstractions

Now let's take a look at the various abstraction levels available, and what they
can (or cannot) reuse. For this we can use the following table, which defines
the various abstractions and what they can (not) reuse:

| Abstraction            | Service classes  | Finders  | Presenters  | Serializers   | Model instance method   | Model class methods   | Active Record   | Worker
|:-----------------------|:-----------------|:---------|:------------|:--------------|:------------------------|:----------------------|:----------------|:--------
| Controller/API endpoint| Yes              | Yes      | Yes         | Yes           | Yes                     | No                    | No              | No
| Service class          | Yes              | Yes      | No          | No            | Yes                     | No                    | No              | Yes
| Finder                 | No               | No       | No          | No            | Yes                     | Yes                   | No              | No
| Presenter              | No               | Yes      | No          | No            | Yes                     | Yes                   | No              | No
| Serializer             | No               | Yes      | No          | No            | Yes                     | Yes                   | No              | No
| Model class method     | No               | No       | No          | No            | Yes                     | Yes                   | Yes             | No
| Model instance method  | No               | Yes      | No          | No            | Yes                     | Yes                   | Yes             | Yes
| Worker                 | Yes              | Yes      | No          | No            | Yes                     | No                    | No              | Yes

### Controllers

Everything in `app/controllers`.

Controllers should not do much work on their own, instead they pass input
to other classes and present the results.

### API endpoints

Everything in `lib/api` (the REST API) and `app/graphql` (the GraphQL API).

API endpoints have the same abstraction level as controllers.

### Service classes

Everything that resides in `app/services`.

Service classes represent operations that coordinates changes between models
(such as entities and value objects). Changes impact the state of the application.

1. When an object makes no changes to the state of the application, then it's not a service.
   It may be a [finder](#finders) or a value object.
1. When there is no operation, there is no need to execute a service. The class would
   probably be better designed as an entity, a value object, or a policy.

When implementing a service class, consider using the following patterns:

1. A service class initializer should contain in its arguments:
   1. A [model](#models) instance that is being acted upon. Should be first positional
      argument of the initializer. The argument name of the argument is left to the
      developer's discretion, such as: `issue`, `project`, `merge_request`.
   1. When service represents an action initiated by a user or executed in the
      context of a user, the initializer must have the `current_user:` keyword argument.
      Services with the `current_user:` argument run high-level business logic
      and must validate user authorization to perform their operations.
   1. When service does not have a user context and it's not directly initiated
      by a user (like background service or side-effects), the `current_user:`
      argument is not needed. This describes low-level domain logic or instance-wide logic.
   1. For all additional data required by a service, the explicit keyword arguments are recommended.
      When a service requires too long of a list of arguments, consider splitting them into:
      - `params`: A hash with model properties that will be assigned directly.
      - `options`: A hash with extra parameters (which need to be processed,
        and are not model properties). The `options` hash should be stored in an instance variable.

      ```ruby
      # merge_request: A model instance that is being acted upon.
      # assignee: new MR assignee that will be assigned to the MR
      #   after the service is executed.
      def initialize(merge_request, assignee:)
        @merge_request = merge_request
        @assignee = assignee
      end
      ```

      ```ruby
      # issue: A model instance that is being acted upon.
      # current_user: Current user.
      # params: Model properties.
      # options: Configuration for this service. Can be any of the following:
      #   - notify: Whether to send a notification to the current user.
      #   - cc: Email address to copy when sending a notification.
      def initialize(issue:, current_user:, params: {}, options: {})
        @issue = issue
        @current_user = current_user
        @params = params
        @options = options
      end
      ```

1. The service class should implements a single public instance method `#execute`, which invokes service class behavior:
   - The `#execute` method takes no arguments. All required data is passed into initializer.

1. If a return value is needed, the `#execute` method should returns its result via [`ServiceResponse`](#serviceresponse) object.

Several base classes implement the service classes convention. You may consider inheriting from:

- `BaseContainerService` for services scoped by container (project or group).
- `BaseProjectService` for services scoped to projects.
- `BaseGroupService` for services scoped to groups.

For some domains or [bounded contexts](software_design.md#bounded-contexts), it may make sense for
service classes to use different patterns. For example, the Remote Development domain uses a
[layered architecture](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#layered-architecture)
with domain logic isolated to a separate domain layer following a standard pattern, which allows for a very
[minimal service layer](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#minimal-service-layer)
which consists of only a single reusable `CommonService` class. It also uses
[functional patterns with stateless singleton class methods](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#functional-patterns).
See the Remote Development [service layer code example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#service-layer-code-example) for more details.
However, even though the invocation signature of services via this pattern is different,
it still respects the standard Service layer contracts of always returning all results via a
[`ServiceResponse`](#serviceresponse) object, and performing
[defense-in-depth authorization](permissions/authorizations.md#where-should-permissions-be-checked).

Classes that are not service objects should be
[created elsewhere](software_design.md#use-namespaces-to-define-bounded-contexts),
such as in `lib`.

#### ServiceResponse

Service classes usually have an `execute` method, which can return a
`ServiceResponse`. You can use `ServiceResponse.success` and
`ServiceResponse.error` to return a response in `execute` method.

In a successful case:

```ruby
response = ServiceResponse.success(message: 'Branch was deleted')

response.success? # => true
response.error? # => false
response.status # => :success
response.message # => 'Branch was deleted'
```

In a failed case:

```ruby
response = ServiceResponse.error(message: 'Unsupported operation')

response.success? # => false
response.error? # => true
response.status # => :error
response.message # => 'Unsupported operation'
```

An additional payload can also be attached:

```ruby
response = ServiceResponse.success(payload: { issue: issue })

response.payload[:issue] # => issue
```

Error responses can also specify the failure `reason` which can be used by the caller
to understand the nature of the failure.
The caller, if an HTTP endpoint, could translate the reason symbol into an HTTP status code:

```ruby
response = ServiceResponse.error(
  message: 'Job is in a state that cannot be retried',
  reason: :job_not_retrieable)

if response.success?
  head :ok
elsif response.reason == :job_not_retriable
  head :unprocessable_entity
else
  head :bad_request
end
```

For common failures such as resource `:not_found` or operation `:forbidden`, we could
leverage the Rails [HTTP status symbols](http://www.railsstatuscodes.com/) as long as
they are sufficiently specific for the domain logic involved.
For other failures use domain-specific reasons whenever possible.

For example: `:job_not_retriable`, `:duplicate_package`, `:merge_request_not_mergeable`.

### Finders

Everything in `app/finders`, typically used for retrieving data from a database.

Finders cannot reuse other finders in an attempt to better control the SQL
queries they produce.

Finders' `execute` method should return `ActiveRecord::Relation`. Exceptions
can be added to `spec/support/finder_collection_allowlist.yml`.
See [`#298771`](https://gitlab.com/gitlab-org/gitlab/-/issues/298771) for more details.

### Presenters

Everything in `app/presenters`, used for exposing complex data to a Rails view,
without having to create many instance variables.

See [the documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/presenters/README.md) for more information.

### Serializers

Everything in `app/serializers`, used for presenting the response to a request,
typically in JSON.

### Models

Classes and modules in `app/models` represent domain concepts that encapsulate both
[data and behavior](https://en.wikipedia.org/wiki/Domain_model).

These classes can interact directly with a data store (like ActiveRecord models) or
can be a thin wrapper (Plain Old Ruby Objects) on top of ActiveRecord models to express a
richer domain concept.

[Entities and Value Objects](https://martinfowler.com/bliki/EvansClassification.html)
that represent domain concepts are considered domain models.

Some examples:

- [`DesignManagement::DesignAtVersion`](https://gitlab.com/gitlab-org/gitlab/-/blob/b62ce98cff8e0530210670f9cb0314221181b77f/app/models/design_management/design_at_version.rb)
  is a model that leverages validations to combine designs and versions.
- [`Ci::Minutes::Usage`](https://gitlab.com/gitlab-org/gitlab/-/blob/ec52f19f7325410177c00fef06379f55ab7cab67/ee/app/models/ci/minutes/usage.rb)
  is a Value Object that provides [compute usage](../ci/pipelines/compute_minutes.md)
  for a given namespace.

#### Model class methods

These are class methods defined by _GitLab itself_, including the following
methods provided by Active Record:

- `find`
- `find_by_id`
- `delete_all`
- `destroy`
- `destroy_all`

Any other methods such as `find_by(some_column: X)` are not included, and
instead fall under the "Active Record" abstraction.

#### Model instance methods

Instance methods defined on Active Record models by _GitLab itself_. Methods
provided by Active Record are not included, except for the following methods:

- `save`
- `update`
- `destroy`
- `delete`

#### Active Record

The API provided by Active Record itself, such as the `where` method, `save`,
`delete_all`, and so on.

### Worker

Everything in `app/workers`.

Use `SomeWorker.perform_async` or `SomeWorker.perform_in` to schedule Sidekiq
jobs. Never directly invoke a worker using `SomeWorker.new.perform`.
