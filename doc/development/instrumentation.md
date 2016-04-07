# Instrumenting Ruby Code

GitLab Performance Monitoring allows instrumenting of custom blocks of Ruby
code. This can be used to measure the time spent in a specific part of a larger
chunk of code. The resulting data is written to a separate series.

To start measuring a block of Ruby code you should use
`Gitlab::Metrics.measure` and give it a name for the series to store the data
in:

```ruby
Gitlab::Metrics.measure(:user_logins) do
  ...
end
```

The first argument of this method is the series name and should be plural. This
name will be prefixed with `rails_` or `sidekiq_` depending on whether the code
was run in the Rails application or one of the Sidekiq workers. In the
above example the final series names would be as follows:

- rails_user_logins
- sidekiq_user_logins

Series names should be plural as this keeps the naming style in line with the
other series names.

By default metrics measured using a block contain a single value, "duration",
which contains the number of milliseconds it took to execute the block. Custom
values can be added by passing a Hash as the 2nd argument. Custom tags can be
added by passing a Hash as the 3rd argument. A simple example is as follows:

```ruby
Gitlab::Metrics.measure(:example_series, { number: 10 }, { class: self.class.to_s }) do
  ...
end
```
