# Instrumenting Ruby Code

GitLab Performance Monitoring allows instrumenting of both methods and custom
blocks of Ruby code. Method instrumentation is the primary form of
instrumentation with block-based instrumentation only being used when we want to
drill down to specific regions of code within a method.

## Instrumenting Methods

Instrumenting methods is done by using the `Gitlab::Metrics::Instrumentation`
module. This module offers a few different methods that can be used to
instrument code:

* `instrument_method`: instruments a single class method.
* `instrument_instance_method`: instruments a single instance method.
* `instrument_class_hierarchy`: given a Class this method will recursively
  instrument all sub-classes (both class and instance methods).
* `instrument_methods`: instruments all public and private class methods of a Module.
* `instrument_instance_methods`: instruments all public and private instance methods of a
  Module.

To remove the need for typing the full `Gitlab::Metrics::Instrumentation`
namespace you can use the `configure` class method. This method simply yields
the supplied block while passing `Gitlab::Metrics::Instrumentation` as its
argument. An example:

```
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_method(Foo, :bar)
  conf.instrument_method(Foo, :baz)
end
```

Using this method is in general preferred over directly calling the various
instrumentation methods.

Method instrumentation should be added in the initializer
`config/initializers/metrics.rb`.

### Examples

Instrumenting a single method:

```
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_method(User, :find_by)
end
```

Instrumenting an entire class hierarchy:

```
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_class_hierarchy(ActiveRecord::Base)
end
```

Instrumenting all public class methods:

```
Gitlab::Metrics::Instrumentation.configure do |conf|
  conf.instrument_methods(User)
end
```

### Checking Instrumented Methods

The easiest way to check if a method has been instrumented is to check its
source location. For example:

```
method = Rugged::TagCollection.instance_method(:[])

method.source_location
```

If the source location points to `lib/gitlab/metrics/instrumentation.rb` you
know the method has been instrumented.

If you're using Pry you can use the `$` command to display the source code of a
method (along with its source location), this is easier than running the above
Ruby code. In case of the above snippet you'd run the following:

```
$ Rugged::TagCollection#[]
```

This will print out something along the lines of:

```
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

3 values are measured for a block:

1. The real time elapsed, stored in NAME_real_time.
2. The CPU time elapsed, stored in NAME_cpu_time.
3. The call count, stored in NAME_call_count.

Both the real and CPU timings are measured in milliseconds.

Multiple calls to the same block will result in the final values being the sum
of all individual values. Take this code for example:

```ruby
3.times do
  Gitlab::Metrics.measure(:sleep) do
    sleep 1
  end
end
```

Here the final value of `sleep_real_time` will be `3`, _not_ `1`.

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
