# Testing with feature flags

To run a specific test with a feature flag enabled you can use the `QA::Runtime::Feature` class to enabled and disable feature flags ([via the API](../../../api/features.md)).

```ruby
context "with feature flag enabled" do
  before do
    Runtime::Feature.enable('feature_flag_name')
  end

  it "feature flag test" do
    # Execute a test with a feature flag enabled
  end

  after do
    Runtime::Feature.disable('feature_flag_name')
  end
end
```

## Running a scenario with a feature flag enabled

It's also possible to run an entire scenario with a feature flag enabled, without having to edit existing tests or write new ones.

Please see the [QA readme](https://gitlab.com/gitlab-org/gitlab/tree/master/qa#running-tests-with-a-feature-flag-enabled) for details.
