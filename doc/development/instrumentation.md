---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Instrumenting Ruby code **(FREE)**

[GitLab Performance Monitoring](../administration/monitoring/performance/index.md) allows instrumenting of both methods and custom
blocks of Ruby code. Method instrumentation is the primary form of
instrumentation with block-based instrumentation only being used when we want to
drill down to specific regions of code within a method.

Please refer to [Product Intelligence](https://about.gitlab.com/handbook/product/product-intelligence-guide/) if you are tracking product usage patterns.

## Instrumenting Methods

Instrumenting methods is done by using the `Gitlab::Metrics::Instrumentation`
module. This module offers a few different methods that can be used to
instrument code:

- `instrument_method`: Instruments a single class method.
- `instrument_instance_method`: Instruments a single instance method.
- `instrument_class_hierarchy`: Given a Class, this method recursively
  instruments all sub-classes (both class and instance methods).
- `instrument_methods`: Instruments all public and private class methods of a
  Module.
- `instrument_instance_methods`: Instruments all public and private instance
  methods of a Module.

To remove the need for typing the full `Gitlab::Metrics::Instrumentation`
namespace you can use the `configure` class method. This method simply yields
the supplied block while passing `Gitlab::Metrics::Instrumentation` as its
argument. An example:

```ruby
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_method(Foo, :bar)
  conf.instrument_method(Foo, :baz)
end
```

Using this method is in general preferred over directly calling the various
instrumentation methods.

Method instrumentation should be added in the initializer
`config/initializers/zz_metrics.rb`.

### Examples

Instrumenting a single method:

```ruby
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_method(User, :find_by)
end
```

Instrumenting an entire class hierarchy:

```ruby
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_class_hierarchy(ActiveRecord::Base)
end
```

Instrumenting all public class methods:

```ruby
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_methods(User)
end
```

### Checking Instrumented Methods

The easiest way to check if a method has been instrumented is to check its
source location. For example:

```ruby
method = Banzai::Renderer.method(:render)

method.source_location
```

If the source location points to `lib/gitlab/metrics/instrumentation.rb` you
know the method has been instrumented.

If you're using Pry you can use the `$` command to display the source code of a
method (along with its source location), this is easier than running the above
Ruby code. In case of the above snippet you'd run the following:

- `$ Banzai::Renderer.render`

This prints a result similar to:

```plaintext
From: /path/to/your/gitlab/lib/gitlab/metrics/instrumentation.rb @ line 148:
Owner: #<Module:0x0055f0865c6d50>
Visibility: public
Number of lines: 21

def #{name}(#{args_signature})
  if trans = Gitlab::Metrics::Instrumentation.transaction
    trans.measure_method(#{label.inspect}) { super }
  else
    super
  end
end
```

## Instrumenting Ruby Blocks

Measuring blocks of Ruby code is done by calling `Gitlab::Metrics.measure` and
passing it a block. For example:

```ruby
Gitlab::Metrics.measure(:foo) do
  ...
end
```

The block is executed and the execution time is stored as a set of fields in the
currently running transaction. If no transaction is present the block is yielded
without measuring anything.

Three values are measured for a block:

- The real time elapsed, stored in `NAME_real_time`.
- The CPU time elapsed, stored in `NAME_cpu_time`.
- The call count, stored in `NAME_call_count`.

Both the real and CPU timings are measured in milliseconds.

Multiple calls to the same block results in the final values being the sum
of all individual values. Take this code for example:

```ruby
3.times do
  Gitlab::Metrics.measure(:sleep) do
    sleep 1
  end
end
```

Here, the final value of `sleep_real_time` is `3`, and not `1`.

## Tracking Custom Events

Besides instrumenting code GitLab Performance Monitoring also supports tracking
of custom events. This is primarily intended to be used for tracking business
metrics such as the number of Git pushes, repository imports, and so on.

To track a custom event simply call `Gitlab::Metrics.add_event` passing it an
event name and a custom set of (optional) tags. For example:

```ruby
Gitlab::Metrics.add_event(:user_login, email: current_user.email)
```

Event names should be verbs such as `push_repository` and `remove_branch`.
