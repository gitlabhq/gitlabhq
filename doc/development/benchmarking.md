# Benchmarking

GitLab CE comes with a set of benchmarks that are executed for every build. This
makes it easier to measure performance of certain components over time.

Benchmarks are written as RSpec tests using a few extra helpers. To write a
benchmark, first tag the top-level `describe`:

```ruby
describe MaruTheCat, benchmark: true do

end
```

This ensures the benchmark is executed separately from other test collections.
It also exposes the various RSpec matchers used for writing benchmarks to the
test group.

Next, lets write the actual benchmark:

```ruby
describe MaruTheCat, benchmark: true do
  let(:maru) { MaruTheChat.new }

  describe '#jump_in_box' do
    benchmark_subject { maru.jump_in_box }

    it { is_expected.to iterate_per_second(9000) }
  end
end
```

Here `benchmark_subject` is a small wrapper around RSpec's `subject` method that
makes it easier to specify the subject of a benchmark. Using RSpec's regular
`subject` would require us to write the following instead:

```ruby
subject { -> { maru.jump_in_box } }
```

The `iterate_per_second` matcher defines the amount of times per second a
subject should be executed. The higher the amount of iterations the better.

By default the allowed standard deviation is a maximum of 30%. This can be
adjusted by chaining the `with_maximum_stddev` on the `iterate_per_second`
matcher:

```ruby
it { is_expected.to iterate_per_second(9000).with_maximum_stddev(50) }
```

This can be useful if the code in question depends on external resources of
which the performance can vary a lot (e.g. physical HDDs, network calls, etc).
However, in most cases 30% should be enough so only change this when really
needed.

## Benchmarks Location

Benchmarks should be stored in `spec/benchmarks` and should follow the regular
Rails specs structure. That is, model benchmarks go in `spec/benchmark/models`,
benchmarks for code in the `lib` directory go in `spec/benchmarks/lib`, etc.

## Underlying Technology

The benchmark setup uses [benchmark-ips][benchmark-ips] which takes care of the
heavy lifting such as warming up code, calculating iterations, standard
deviation, etc.

[benchmark-ips]: https://github.com/evanphx/benchmark-ips
