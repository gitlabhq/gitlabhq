---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Implementing an A/B/n experiment
---

## Implementing an experiment

[Examples](https://gitlab.com/groups/gitlab-org/growth/-/wikis/GLEX-How-Tos)

Start by generating a feature flag using the `bin/feature-flag` command as you
usually would for a development feature flag, making sure to use `experiment` for
the type. For the sake of documentation let's name our feature flag (and experiment)
`pill_color`.

```shell
bin/feature-flag pill_color -t experiment
```

After you generate the desired feature flag, you can immediately implement an
experiment in code. A basic experiment implementation can be:

```ruby
experiment(:pill_color, actor: current_user) do |e|
  e.control { 'control' }
  e.variant(:red) { 'red' }
  e.variant(:blue) { 'blue' }
end
```

When this code executes, the experiment is run, a variant is assigned, and (if in a
controller or view) a `window.gl.experiments.pill_color` object is available in the
client layer, with details like:

- The assigned variant.
- The context key for client tracking events.

In addition, when an experiment runs, an event is tracked for
the experiment `:assignment`. We cover more about events, tracking, and
the client layer later.

In local development, you can make the experiment active by using the feature flag
interface. You can also target specific cases by providing the relevant experiment
to the call to enable the feature flag:

```ruby
# Enable for everyone
Feature.enable(:pill_color)

# Get the `experiment` method -- already available in controllers, views, and mailers.
include Gitlab::Experiment::Dsl
# Enable for only the first user
Feature.enable(:pill_color, experiment(:pill_color, actor: User.first))
```

To roll out your experiment feature flag on an environment, run
the following command using ChatOps (which is covered in more depth in the
[Feature flags in development of GitLab](../feature_flags/_index.md) documentation).
This command creates a scenario where half of everyone who encounters
the experiment would be assigned the _control_, 25% would be assigned the _red_
variant, and 25% would be assigned the _blue_ variant:

```slack
/chatops run feature set pill_color 50 --actors
```

For an even distribution in this example, change the command to set it to 66% instead
of 50.

NOTE:
To immediately stop running an experiment, use the
`/chatops run feature set pill_color false` command.

WARNING:
We strongly recommend using the `--actors` flag when using the ChatOps commands,
as anything else may give odd behaviors due to how the caching of variant assignment is
handled.

We can also implement this experiment in a HAML file with HTML wrappings:

```haml
#cta-interface
  - experiment(:pill_color, actor: current_user) do |e|
    - e.control do
      .pill-button control
    - e.variant(:red) do
      .pill-button.red red
    - e.variant(:blue) do
      .pill-button.blue blue
```

### The importance of context

In our previous example experiment, our context (this is an important term) is a hash
that's set to `{ actor: current_user }`. Context must be unique based on how you
want to run your experiment, and should be understood at a lower level.

It's expected, and recommended, that you use some of these
contexts to simplify reporting:

- `{ actor: current_user }`: Assigns a variant and is "sticky" to each user
  (or "client" if `current_user` is nil) who enters the experiment.
- `{ project: project }`: Assigns a variant and is "sticky" to the project
  being viewed. If running your experiment is more useful when viewing a project,
  rather than when a specific user is viewing any project, consider this approach.
- `{ group: group }`: Similar to the project example, but applies to a wider
  scope of projects and users.
- `{ actor: current_user, project: project }`: Assigns a variant and is "sticky"
  to the user who is viewing the given project. This creates a different variant
  assignment possibility for every project that `current_user` views. Understand this
  can create a large cache size if an experiment like this in a highly trafficked part
  of the application.
- `{ wday: Time.current.wday }`: Assigns a variant based on the current day of the
  week. In this example, it would consistently assign one variant on Friday, and a
  potentially different variant on Saturday.

Context is critical to how you define and report on your experiment. It's usually
the most important aspect of how you choose to implement your experiment, so consider
it carefully, and discuss it with the wider team if needed. Also, take into account
that the context you choose affects our cache size.

After the above examples, we can state the general case: *given a specific
and consistent context, we can provide a consistent experience and track events for
that experience.* To dive a bit deeper into the implementation details: a context key
is generated from the context that's provided. Use this context key to:

- Determine the assigned variant.
- Identify events tracked against that context key.

We can think about this as the experience that we've rendered, which is both dictated
and tracked by the context key. The context key is used to track the interaction and
results of the experience we've rendered to that context key. These concepts are
somewhat abstract and hard to understand initially, but this approach enables us to
communicate about experiments as something that's wider than just user behavior.

NOTE:
Using `actor:` uses cookies if the `current_user` is nil. If you don't need
cookies though - meaning that the exposed functionality would only be visible to
authenticated users - `{ user: current_user }` would be just as effective.

WARNING:
The caching of variant assignment is done by using this context, and so consider
your impact on the cache size when defining your experiment. If you use
`{ time: Time.current }` you would be inflating the cache size every time the
experiment is run. Not only that, your experiment would not be "sticky" and events
wouldn't be resolvable.

### Advanced experimentation

There are two ways to implement an experiment:

1. The basic experiment style described previously.
1. A more advanced style where an experiment class is provided.

The advanced style is handled by naming convention, and works similar to what you
would expect in Rails.

To generate a custom experiment class that can override the defaults in
`ApplicationExperiment` use the Rails generator:

```shell
rails generate gitlab:experiment pill_color control red blue
```

This generates an experiment class in `app/experiments/pill_color_experiment.rb`
with the _behaviors_ we've provided to the generator. Here's an example
of how that class would look after migrating our previous example into it:

```ruby
class PillColorExperiment < ApplicationExperiment
  control { 'control' }
  variant(:red) { 'red' }
  variant(:blue) { 'blue' }
end
```

We can now simplify where we run our experiment to the following call, instead of
providing the block we were initially providing, by explicitly calling `run`:

```ruby
experiment(:pill_color, actor: current_user).run
```

The _behaviors_ we defined in our experiment class represent the default
implementation. You can still use the block syntax to override these _behaviors_
however, so the following would also be valid:

```ruby
experiment(:pill_color, actor: current_user) do |e|
  e.control { '<strong>control</strong>' }
end
```

NOTE:
When passing a block to the `experiment` method, it is implicitly invoked as
if `run` has been called.

#### Segmentation rules

You can use runtime segmentation rules to, for instance, segment contexts into a specific
variant. The `segment` method is a callback (like `before_action`) and so allows providing
a block or method name.

In this example, any user named `'Richard'` would always be assigned the _red_
variant, and any account older than 2 weeks old would be assigned the _blue_ variant:

```ruby
class PillColorExperiment < ApplicationExperiment
  # ...registered behaviors

  segment(variant: :red) { context.actor.first_name == 'Richard' }
  segment :old_account?, variant: :blue

  private

  def old_account?
    context.actor.created_at < 2.weeks.ago
  end
end
```

When an experiment runs, the segmentation rules are executed in the order they're
defined. The first segmentation rule to produce a truthy result assigns the variant.

In our example, any user named `'Richard'`, regardless of account age, is always
assigned the _red_ variant. If you want the opposite logic, flip the order.

NOTE:
Keep in mind when defining segmentation rules: after a truthy result, the remaining
segmentation rules are skipped to achieve optimal performance.

#### Exclusion rules

Exclusion rules are similar to segmentation rules, but are intended to determine
if a context should even be considered as something we should include in the experiment
and track events toward. Exclusion means we don't care about the events in relation
to the given context.

These examples exclude all users named `'Richard'`, *and* any account
older than 2 weeks old. Not only are they given the control behavior - which could
be nothing - but no events are tracked in these cases as well.

```ruby
class PillColorExperiment < ApplicationExperiment
  # ...registered behaviors

  exclude :old_account?, ->{ context.actor.first_name == 'Richard' }

  private

  def old_account?
    context.actor.created_at < 2.weeks.ago
  end
end
```

You may also need to check exclusion in custom tracking logic by calling `should_track?`:

```ruby
class PillColorExperiment < ApplicationExperiment
  # ...registered behaviors

  def expensive_tracking_logic
    return unless should_track?

    track(:my_event, value: expensive_method_call)
  end
end
```

### Tracking events

One of the most important aspects of experiments is gathering data and reporting on
it. You can use the `track` method to track events across an experimental implementation.
You can track events consistently to an experiment if you provide the same context between
calls to your experiment. If you do not understand context, you should read
about contexts now.

We can assume we run the experiment in one or a few places, but
track events potentially in many places. The tracking call remains the same, with
the arguments you would usually use when
tracking events using snowplow. The easiest example
of tracking an event in Ruby would be:

```ruby
experiment(:pill_color, actor: current_user).track(:clicked)
```

When you run an experiment with any of the examples so far, an `:assignment` event
is tracked automatically by default. All events that are tracked from an
experiment have a special
[experiment context](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_experiment/jsonschema/1-0-3)
added to the event. This can be used - typically by the data team - to create a connection
between the events on a given experiment.

If our user hasn't encountered the experiment (meaning where the experiment
is run), and we track an event for them, they are assigned a variant and see
that variant if they ever encountered the experiment later, when an `:assignment`
event would be tracked at that time for them.

NOTE:
GitLab tries to be sensitive and respectful of our customers regarding tracking,
so our experimentation library allows us to implement an experiment without ever tracking identifying
IDs. It's not always possible, though, based on experiment reporting requirements.
You may be asked from time to time to track a specific record ID in experiments.
The approach is largely up to the PM and engineer creating the implementation.
No recommendations are provided here at this time.

## Experiments in the client layer

Any experiment that's been run in the request lifecycle surfaces in `window.gl.experiments`,
and matches [this schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_experiment/jsonschema/1-0-3)
so it can be used when resolving experimentation in the client layer.

Given that we've defined a class for our experiment, and have defined the variants for it, we can publish that experiment in a couple ways.

The first way is by running the experiment. Assuming the experiment has been run, it surfaces in the client layer without having to do anything special.

The second way doesn't run the experiment and is intended to be used if the experiment must only surface in the client layer. To accomplish this we can `.publish` the experiment. This does not run any logic, but does surface the experiment details in the client layer so they can be used there.

An example might be to publish an experiment in a `before_action` in a controller. Assuming we've defined the `PillColorExperiment` class, like we have above, we can surface it to the client by publishing it instead of running it:

```ruby
before_action -> { experiment(:pill_color).publish }, only: [:show]
```

You can then see this surface in the JavaScript console:

```javascript
window.gl.experiments // => { pill_color: { excluded: false, experiment: "pill_color", key: "ca63ac02", variant: "candidate" } }
```

### Using experiments in Vue

With the `gitlab-experiment` component, you can define slots that match the name of the
variants pushed to `window.gl.experiments`.

We can make use of the named slots in the Vue component, that match the behaviors defined in :

```vue
<script>
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

export default {
  components: { GitlabExperiment }
}
</script>

<template>
  <gitlab-experiment name="pill_color">
    <template #control>
      <button class="bg-default">Click default button</button>
    </template>

    <template #red>
      <button class="bg-red">Click red button</button>
    </template>

    <template #blue>
      <button class="bg-blue">Click blue button</button>
    </template>
  </gitlab-experiment>
</template>
```

NOTE:
When there is no experiment data in the `window.gl.experiments` object for the given experiment name, the `control` slot is used, if it exists.
