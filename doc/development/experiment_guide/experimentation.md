---
stage: Growth
group: Activation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create an A/B test with `Experimentation Module`

NOTE:
We recommend using [GLEX](gitlab_experiment.md) for new experiments.

## Implement the experiment

1. Add the experiment to the `Gitlab::Experimentation::EXPERIMENTS` hash in
   [`experimentation.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib%2Fgitlab%2Fexperimentation.rb):

   ```ruby
   EXPERIMENTS = {
     other_experiment: {
       #...
     },
     # Add your experiment here:
     signup_flow: {
       tracking_category: 'Growth::Activation::Experiment::SignUpFlow' # Used for providing the category when setting up tracking data
     }
   }.freeze
   ```

1. Use the experiment in the code.

   Experiments can be performed on a `subject`. The provided `subject` should
   respond to `to_global_id` or `to_s`.
   The resulting string is bucketed and assigned to either the control or the
   experimental group, so you must always provide the same `subject`
   for an experiment to have the same experience.

   1. Use this standard for the experiment in a controller:

      - Experiment run for a user:

        ```ruby
        class ProjectController < ApplicationController
          def show
            # experiment_enabled?(:experiment_key) is also available in views and helpers
            if experiment_enabled?(:signup_flow, subject: current_user)
              # render the experiment
            else
              # render the original version
            end
          end
        end
        ```

      - Experiment run for a namespace:

        ```ruby
        if experiment_enabled?(:signup_flow, subject: namespace)
          # experiment code
        else
          # control code
        end
        ```

      When no subject is given, it falls back to a cookie that gets set and is consistent until
      the cookie gets deleted.

      ```ruby
      class RegistrationController < ApplicationController
        def show
          # falls back to a cookie
          if experiment_enabled?(:signup_flow)
            # render the experiment
          else
            # render the original version
          end
        end
      end
      ```

   1. Make the experiment available to the frontend in a controller. This example
      checks whether the experiment is enabled and pushes the result to the frontend:

     ```ruby
     before_action do
       push_frontend_experiment(:signup_flow, subject: current_user)
     end
     ```

     You can check the state of the feature flag in JavaScript:

     ```javascript
     import { isExperimentEnabled } from '~/experimentation';

     if ( isExperimentEnabled('signupFlow') ) {
       // ...
     }
     ```

You can also run an experiment outside of the controller scope, such as in a worker:

```ruby
class SomeWorker
  def perform
    # Check if the experiment is active at all (the percentage_of_time_value > 0)
    return unless Gitlab::Experimentation.active?(:experiment_key)

    # Since we cannot access cookies in a worker, we need to bucket models
    # based on a unique, unchanging attribute instead.
    # It is therefore necessery to always provide the same subject.
    if Gitlab::Experimentation.in_experiment_group?(:experiment_key, subject: user)
      # execute experimental code
    else
      # execute control code
    end
  end
end
```

## Implement tracking events

To determine whether the experiment is a success or not, we must implement tracking events
to acquire data for analyzing. We can send events to Snowplow via either the backend or frontend.
Read the [product intelligence guide](https://about.gitlab.com/handbook/product/product-intelligence-guide/) for more details.

### Track backend events

The framework provides a helper method that is available in controllers:

```ruby
before_action do
  track_experiment_event(:signup_flow, 'action', 'value', subject: current_user)
end
```

To test it:

```ruby
context 'when the experiment is active and the user is in the experimental group' do
  before do
    stub_experiment(signup_flow: true)
    stub_experiment_for_subject(signup_flow: true)
  end

  it 'tracks an event', :snowplow do
    subject

    expect_snowplow_event(
      category: 'Growth::Activation::Experiment::SignUpFlow',
      action: 'action',
      value: 'value',
      label: 'experimentation_subject_id',
      property: 'experimental_group'
    )
  end
end
```

### Track frontend events

The framework provides a helper method that is available in controllers:

```ruby
before_action do
  push_frontend_experiment(:signup_flow, subject: current_user)
  frontend_experimentation_tracking_data(:signup_flow, 'action', 'value', subject: current_user)
end
```

This pushes tracking data to `gon.experiments` and `gon.tracking_data`.

```ruby
expect(Gon.experiments['signupFlow']).to eq(true)

expect(Gon.tracking_data).to eq(
  {
    category: 'Growth::Activation::Experiment::SignUpFlow',
    action: 'action',
    value: 'value',
    label: 'experimentation_subject_id',
    property: 'experimental_group'
  }
)
```

To track it:

```javascript
import { isExperimentEnabled } from '~/lib/utils/experimentation';
import Tracking from '~/tracking';

document.addEventListener('DOMContentLoaded', () => {
  const signupFlowExperimentEnabled = isExperimentEnabled('signupFlow');

  if (signupFlowExperimentEnabled && gon.tracking_data) {
    const { category, action, ...data } = gon.tracking_data;

    Tracking.event(category, action, data);
  }
}
```

To test it in Jest:

```javascript
import { withGonExperiment } from 'helpers/experimentation_helper';
import Tracking from '~/tracking';

describe('event tracking', () => {
  describe('with tracking data', () => {
    withGonExperiment('signupFlow');

    beforeEach(() => {
      jest.spyOn(Tracking, 'event').mockImplementation(() => {});

      gon.tracking_data = {
        category: 'Growth::Activation::Experiment::SignUpFlow',
        action: 'action',
        value: 'value',
        label: 'experimentation_subject_id',
        property: 'experimental_group'
      };
    });

    it('should track data', () => {
      performAction()

      expect(Tracking.event).toHaveBeenCalledWith(
        'Growth::Activation::Experiment::SignUpFlow',
        'action',
        {
          value: 'value',
          label: 'experimentation_subject_id',
          property: 'experimental_group'
        },
      );
    });
  });
});
```

## Record experiment user

In addition to the anonymous tracking of events, we can also record which users
have participated in which experiments, and whether they were given the control
experience or the experimental experience.

The `record_experiment_user` helper method is available to all controllers, and it
enables you to record these experiment participants (the current user) and which
experience they were given:

```ruby
before_action do
  record_experiment_user(:signup_flow)
end
```

Subsequent calls to this method for the same experiment and the same user have no
effect unless the user is then enrolled into a different experience. This happens
when we roll out the experimental experience to a greater percentage of users.

This data is completely separate from the [events tracking data](#implement-tracking-events).
They are not linked together in any way.

### Add context

You can add arbitrary context data in a hash which gets stored as part of the experiment
user record. New calls to the `record_experiment_user` with newer contexts are merged
deeply into the existing context.

This data can then be used by data analytics dashboards.

```ruby
before_action do
  record_experiment_user(:signup_flow, foo: 42, bar: { a: 22})
  # context is { "foo" => 42, "bar" => { "a" => 22 }}
end

# Additional contexts for newer record calls are merged deeply
record_experiment_user(:signup_flow, foo: 40, bar: { b: 2 }, thor: 3)
# context becomes { "foo" => 40, "bar" => { "a" => 22, "b" => 2 }, "thor" => 3}
```

## Record experiment conversion event

Along with the tracking of backend and frontend events and the
[recording of experiment participants](#record-experiment-user), we can also record
when a user performs the desired conversion event action. For example:

- **Experimental experience:** Show an in-product nudge to test if the change causes more
  people to sign up for trials.
- **Conversion event:** The user starts a trial.

The `record_experiment_conversion_event` helper method is available to all controllers.
Use it to record the conversion event for the current user, regardless of whether
the user is in the control or experimental group:

```ruby
before_action do
  record_experiment_conversion_event(:signup_flow)
end
```

Note that the use of this method requires that we have first
[recorded the user](#record-experiment-user) as being part of the experiment.

## Enable the experiment

After all merge requests have been merged, use [ChatOps](../../ci/chatops/index.md) in the
[appropriate channel](../feature_flags/controls.md#communicate-the-change) to start the experiment for 10% of the users.
The feature flag should have the name of the experiment with the `_experiment_percentage` suffix appended.
For visibility, share any commands run against production in the `#s_growth` channel:

  ```shell
  /chatops run feature set signup_flow_experiment_percentage 10
  ```

  If you notice issues with the experiment, you can disable the experiment by removing the feature flag:

  ```shell
  /chatops run feature delete signup_flow_experiment_percentage
  ```

## Add user to experiment group manually

To force the application to add your current user into the experiment group,
add a query string parameter to the path where the experiment runs. If you add the
query string parameter, the experiment works only for this request, and doesn't work
after following links or submitting forms.

For example, to forcibly enable the `EXPERIMENT_KEY` experiment, add `force_experiment=EXPERIMENT_KEY`
to the URL:

```shell
https://gitlab.com/<EXPERIMENT_ENTRY_URL>?force_experiment=<EXPERIMENT_KEY>
```

## Add user to experiment group with a cookie

You can force the current user into the experiment group for `<EXPERIMENT_KEY>`
during the browser session by using your browser's developer tools:

```javascript
document.cookie = "force_experiment=<EXPERIMENT_KEY>; path=/";
```

Use a comma to list more than one experiment to be forced:

```javascript
document.cookie = "force_experiment=<EXPERIMENT_KEY>,<ANOTHER_EXPERIMENT_KEY>; path=/";
```

To clear the experiments, unset the `force_experiment` cookie:

```javascript
document.cookie = "force_experiment=; path=/";
```

## Testing and test helpers

### RSpec

Use the following in RSpec to mock the experiment:

```ruby
context 'when the experiment is active' do
  before do
    stub_experiment(signup_flow: true)
  end

  context 'when the user is in the experimental group' do
    before do
      stub_experiment_for_subject(signup_flow: true)
    end

    it { is_expected.to do_experimental_thing }
  end

  context 'when the user is in the control group' do
    before do
      stub_experiment_for_subject(signup_flow: false)
    end

    it { is_expected.to do_control_thing }
  end
end
```

### Jest

Use the following in Jest to mock the experiment:

```javascript
import { withGonExperiment } from 'helpers/experimentation_helper';

describe('given experiment is enabled', () => {
  withGonExperiment('signupFlow');

  it('should do the experimental thing', () => {
    expect(wrapper.find('.js-some-experiment-triggered-element')).toEqual(expect.any(Element));
  });
});
```
