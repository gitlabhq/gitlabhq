---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Testing experiments
---

## Testing experiments with RSpec

In the course of working with experiments, you might want to use the RSpec
tooling that's built in. This happens automatically for files in `spec/experiments`, but
for other files and specs you want to include it in, you can specify the `:experiment` type:

```ruby
it "tests experiments nicely", :experiment do
end
```

### Stub helpers

You can stub experiments using `stub_experiments`. Pass it a hash using experiment
names as the keys, and the variants you want each to resolve to, as the values:

```ruby
# Ensures the experiments named `:example` & `:example2` are both "enabled" and
# that each will resolve to the given variant (`:my_variant` and `:control`
# respectively).
stub_experiments(example: :my_variant, example2: :control)

experiment(:example) do |e|
  e.enabled? # => true
  e.assigned.name # => 'my_variant'
end

experiment(:example2) do |e|
  e.enabled? # => true
  e.assigned.name # => 'control'
end
```

### Exclusion, segmentation, and behavior matchers

You can also test things like the registered behaviors, the exclusions, and
segmentations using the matchers.

```ruby
class ExampleExperiment < ApplicationExperiment
  control { }
  candidate { '_candidate_' }

  exclude { context.actor.first_name == 'Richard' }
  segment(variant: :candidate) { context.actor.username == 'jejacks0n' }
end

excluded = double(username: 'rdiggitty', first_name: 'Richard')
segmented = double(username: 'jejacks0n', first_name: 'Jeremy')

# register_behavior matcher
expect(experiment(:example)).to register_behavior(:control)
expect(experiment(:example)).to register_behavior(:candidate).with('_candidate_')

# exclude matcher
expect(experiment(:example)).to exclude(actor: excluded)
expect(experiment(:example)).not_to exclude(actor: segmented)

# segment matcher
expect(experiment(:example)).to segment(actor: segmented).into(:candidate)
expect(experiment(:example)).not_to segment(actor: excluded)
```

### Tracking matcher

Tracking events is a major aspect of experimentation. We try
to provide a flexible way to ensure your tracking calls are covered.

You can do this on the instance level or at an "any instance" level:

```ruby
subject = experiment(:example)

expect(subject).to track(:my_event)

subject.track(:my_event)
```

You can use the `on_next_instance` chain method to specify that it happens
on the next instance of the experiment. This helps you if you're calling
`experiment(:example).track` downstream:

```ruby
expect(experiment(:example)).to track(:my_event).on_next_instance

experiment(:example).track(:my_event)
```

A full example of the methods you can chain onto the `track` matcher:

```ruby
expect(experiment(:example)).to track(:my_event, value: 1, property: '_property_')
  .on_next_instance
  .with_context(foo: :bar)
  .for(:variant_name)

experiment(:example, :variant_name, foo: :bar).track(:my_event, value: 1, property: '_property_')
```

## Test with Jest

### Stub Helpers

You can stub experiments using the `stubExperiments` helper defined in `spec/frontend/__helpers__/experimentation_helper.js`.

```javascript
import { stubExperiments } from 'helpers/experimentation_helper';
import { getExperimentData } from '~/experimentation/utils';

describe('when my_experiment is enabled', () => {
  beforeEach(() => {
    stubExperiments({ my_experiment: 'candidate' });
  });

  it('sets the correct data', () => {
    expect(getExperimentData('my_experiment')).toEqual({ experiment: 'my_experiment', variant: 'candidate' });
  });
});
```

NOTE:
This method of stubbing in Jest specs does not automatically un-stub itself at the end of the test. We merge our stubbed experiment in with all the other global data in `window.gl`. If you must remove the stubbed experiments after your test or ensure a clean global object before your test, you must manage the global object directly yourself:

```javascript
describe('tests that care about global state', () => {
  const originalObjects = [];

  beforeEach(() => {
    // For backwards compatibility for now, we're using both window.gon & window.gl
    originalObjects.push(window.gon, window.gl);
  });

  afterEach(() => {
    [window.gon, window.gl] = originalObjects;
  });

  it('stubs experiment in fresh global state', () => {
    stubExperiment({ my_experiment: 'candidate' });
    // ...
  });
})
```
