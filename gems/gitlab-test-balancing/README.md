# Gitlab::TestBalancing

Client for the GitLab [test balancing API](https://docs.gitlab.com/api/test_balancing/).

It distributes tests across the nodes of a [`parallel:`](https://docs.gitlab.com/ci/yaml/#parallel)
CI/CD job based on test durations, so that every node finishes at roughly the same
time. A node seeds the job group's shared pending pool with its static test split,
then repeatedly requests duration-budgeted batches of test splits until the pool is
drained.

## RSpec runner

Use `Gitlab::TestBalancing::Runner::Rspec` to run a balanced RSpec job. Pass this
node's static split; it seeds the pool and runs duration-budgeted batches until
the queue is drained. The caller decides how the static split is computed, so this
works in any RSpec project.

```ruby
require 'gitlab/test_balancing/runner/rspec'

result = Gitlab::TestBalancing::Runner::Rspec.new(
  # This node's static split. expected_duration may be nil.
  test_splits: [
    { path: 'spec/models/user_spec.rb', expected_duration: 12.5 },
    { path: 'spec/features/login_spec.rb', expected_duration: nil }
  ],
  rspec_args: ARGV,     # optional
  logger: Logger.new($stdout) # optional; anything responding to #info/#warn
).run

# `run` never calls exit; the caller decides.
if result.unavailable?
  # Test balancing is not available for the project. Fall back to a static run.
  exec('bundle', 'exec', 'rspec', '--', *files)
else
  exit(result.status)
end
```

`Result` exposes `#status`, `#passed?`, and `#unavailable?`.

## Low-level client

For custom runners (non-RSpec, or a bespoke loop), use the client directly.

```ruby
require 'gitlab/test_balancing/client'

client = Gitlab::TestBalancing::Client.new
# Reads CI_API_V4_URL and CI_JOB_TOKEN from the environment by default.

# Seed this node's static split and claim a first batch. `mode` is "seed" for a
# fresh run, or "retry" when the node is retried or recovered from a crash.
result = client.initialize_balancing([
  { path: 'spec/models/user_spec.rb', expected_duration: 12.5 },
  { path: 'spec/features/login_spec.rb' } # expected_duration defaults server-side
])

batch = result.test_splits

# Keep requesting batches until the queue is drained.
until batch.empty?
  run(batch)
  batch = client.request
end
```

The client raises `Gitlab::TestBalancing::Client::FeatureUnavailableError` when the
API responds `404` (test balancing is not available for the project). Callers
should fall back to a static split in that case.
