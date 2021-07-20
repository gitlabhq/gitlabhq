---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Guidelines for reusing abstractions

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
    finder_options = { include_subgroups: params[:include_subgroups], only_owned: true }
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

A much more reliable (and pleasant) way of dealing with this, is to simply use
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
clearly defining what can be reused where, and what to do when you can not reuse
something. Clearly separating abstractions makes it harder to use the wrong one,
makes it easier to debug the code, and (hopefully) results in fewer performance
problems.

## Abstractions

Now let's take a look at the various abstraction levels available, and what they
can (or cannot) reuse. For this we can use the following table, which defines
the various abstractions and what they can (not) reuse:

| Abstraction            | Service classes  | Finders  | Presenters  | Serializers   | Model instance method   | Model class methods   | Active Record   | Worker
|:-----------------------|:-----------------|:---------|:------------|:--------------|:------------------------|:----------------------|:----------------|:--------
| Controller             | Yes              | Yes      | Yes         | Yes           | Yes                     | No                    | No              | No
| Service class          | Yes              | Yes      | No          | No            | Yes                     | No                    | No              | Yes
| Finder                 | No               | No       | No          | No            | Yes                     | Yes                   | No              | No
| Presenter              | No               | Yes      | No          | No            | Yes                     | Yes                   | No              | No
| Serializer             | No               | Yes      | No          | No            | Yes                     | Yes                   | No              | No
| Model class method     | No               | No       | No          | No            | Yes                     | Yes                   | Yes             | No
| Model instance method  | No               | Yes      | No          | No            | Yes                     | Yes                   | Yes             | Yes
| Worker                 | Yes              | Yes      | No          | No            | Yes                     | No                    | No              | Yes

### Controllers

Everything in `app/controllers`.

Controllers should not do much work on their own, instead they simply pass input
to other classes and present the results.

### Grape endpoint

Everything in `lib/api`.

### Service classes

Everything that resides in `app/services`.

In Service classes the use of `execute` and `#execute` is preferred over `call` and `#call`.

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

### Finders

Everything in `app/finders`, typically used for retrieving data from a database.

Finders can not reuse other finders in an attempt to better control the SQL
queries they produce.

### Presenters

Everything in `app/presenters`, used for exposing complex data to a Rails view,
without having to create many instance variables.

### Serializers

Everything in `app/serializers`, used for presenting the response to a request,
typically in JSON.

### Model class methods

These are class methods defined by _GitLab itself_, including the following
methods provided by Active Record:

- `find`
- `find_by_id`
- `delete_all`
- `destroy`
- `destroy_all`

Any other methods such as `find_by(some_column: X)` are not included, and
instead fall under the "Active Record" abstraction.

### Model instance methods

Instance methods defined on Active Record models by _GitLab itself_. Methods
provided by Active Record are not included, except for the following methods:

- `save`
- `update`
- `destroy`
- `delete`

### Active Record

The API provided by Active Record itself, such as the `where` method, `save`,
`delete_all`, and so on.

### Worker

Everything in `app/workers`.

Use `SomeWorker.perform_async` or `SomeWorker.perform_in` to schedule Sidekiq
jobs. Never directly invoke a worker using `SomeWorker.new.perform`.
