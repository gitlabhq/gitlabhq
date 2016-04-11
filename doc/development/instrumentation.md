# Instrumenting Ruby Code

GitLab Performance Monitoring allows instrumenting of custom blocks of Ruby
code. This can be used to measure the time spent in a specific part of a larger
chunk of code. The resulting data is stored as a field in the transaction that
executed the block.

To start measuring a block of Ruby code you should use `Gitlab::Metrics.measure`
and give it a name:

```ruby
Gitlab::Metrics.measure(:foo) do
  ...
end
```

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
