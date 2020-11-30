---
stage: Growth
group: Activation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Experiment Guide

Experiments can be conducted by any GitLab team, most often the teams from the [Growth Sub-department](https://about.gitlab.com/handbook/engineering/development/growth/). Experiments are not tied to releases because they primarily target GitLab.com.

Experiments are run as an A/B test and are behind a feature flag to turn the test on or off. Based on the data the experiment generates, the team decides if the experiment had a positive impact and should be made the new default or rolled back.

## Experiment tracking issue

Each experiment should have an [Experiment tracking](https://gitlab.com/groups/gitlab-org/-/issues?scope=all&utf8=%E2%9C%93&state=opened&label_name[]=growth%20experiment&search=%22Experiment+tracking%22) issue to track the experiment from roll-out through to cleanup/removal. Immediately after an experiment is deployed, the due date of the issue should be set (this depends on the experiment but can be up to a few weeks in the future).
After the deadline, the issue needs to be resolved and either:

- It was successful and the experiment becomes the new default.
- It was not successful and all code related to the experiment is removed.

In either case, an outcome of the experiment should be posted to the issue with the reasoning for the decision.

## Code reviews

Experiments' code quality can fail our standards for several reasons. These
reasons can include not being added to the codebase for a long time, or because
of fast iteration to retrieve data. However, having the experiment run (or not
run) shouldn't impact GitLab's availability. To avoid or identify issues,
experiments are initially deployed to a small number of users. Regardless,
experiments still need tests.

If, as a reviewer or maintainer, you find code that would usually fail review
but is acceptable for now, mention your concerns with a note that there's no
need to change the code. The author can then add a comment to this piece of code
and link to the issue that resolves the experiment. If the experiment is
successful and becomes part of the product, any follow up issues should be
addressed.

## How to create an A/B test

### Implement the experiment

1. Add the experiment to the `Gitlab::Experimentation::EXPERIMENTS` hash in [`experimentation.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib%2Fgitlab%2Fexperimentation.rb):

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

   - Use this standard for the experiment in a controller:

      ```ruby
      class RegistrationController < ApplicationController
       def show
         # experiment_enabled?(:experiment_key) is also available in views and helpers
         if experiment_enabled?(:signup_flow)
           # render the experiment
         else
           # render the original version
         end
       end
      end
      ```

   - Make the experiment available to the frontend in a controller:

      ```ruby
      before_action do
        push_frontend_experiment(:signup_flow)
      end
      ```

      The above checks whether the experiment is enabled and push the result to the frontend.

      You can check the state of the feature flag in JavaScript:

      ```javascript
      import { isExperimentEnabled } from '~/experimentation';

      if ( isExperimentEnabled('signupFlow') ) {
        // ...
      }
      ```

   - It is also possible to run an experiment outside of the controller scope, for example in a worker:

      ```ruby
      class SomeWorker
        def perform
          # Check if the experiment is enabled at all (the percentage_of_time_value > 0)
          return unless Gitlab::Experimentation.enabled?(:experiment_key)

          # Since we cannot access cookies in a worker, we need to bucket models based on a unique, unchanging attribute instead.
          # Use the following method to check if the experiment is enabled for a certain attribute, for example a username or email address:
          if Gitlab::Experimentation.enabled_for_attribute?(:experiment_key, some_attribute)
            # execute experimental code
          else
            # execute control code
          end
        end
      end
      ```

### Implement the tracking events

To determine whether the experiment is a success or not, we must implement tracking events
to acquire data for analyzing. We can send events to Snowplow via either the backend or frontend.
Read the [product analytics guide](https://about.gitlab.com/handbook/product/product-analytics-guide/) for more details.

#### Track backend events

The framework provides the following helper method that is available in controllers:

```ruby
before_action do
  track_experiment_event(:signup_flow, 'action', 'value')
end
```

Which can be tested as follows:

```ruby
context 'when the experiment is active and the user is in the experimental group' do
  before do
    stub_experiment(signup_flow: true)
    stub_experiment_for_user(signup_flow: true)
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

#### Track frontend events

The framework provides the following helper method that is available in controllers:

```ruby
before_action do
  push_frontend_experiment(:signup_flow)
  frontend_experimentation_tracking_data(:signup_flow, 'action', 'value')
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

Which can then be used for tracking as follows:

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

Which can be tested in Jest as follows:

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

### Record experiment user

In addition to the anonymous tracking of events, we can also record which users have participated in which experiments and whether they were given the control experience or the experimental experience.

The `record_experiment_user` helper method is available to all controllers, and it enables you to record these experiment participants (the current user) and which experience they were given:

```ruby
before_action do
  record_experiment_user(:signup_flow)
end
```

Subsequent calls to this method for the same experiment and the same user have no effect unless the user has gets enrolled into a different experience. This happens when we roll out the experimental experience to a greater percentage of users.

Note that this data is completely separate from the [events tracking data](#implement-the-tracking-events). They are not linked together in any way.

### Record experiment conversion event

Along with the tracking of backend and frontend events and the [recording of experiment participants](#record-experiment-user), we can also record when a user performs the desired conversion event action. For example:

- **Experimental experience:** Show an in-product nudge to see if it causes more people to sign up for trials.
- **Conversion event:** The user starts a trial.

The `record_experiment_conversion_event` helper method is available to all controllers, and enables us to easily record the conversion event for the current user, regardless of whether they are in the control or experimental group:

```ruby
before_action do
  record_experiment_conversion_event(:signup_flow)
end
```

Note that the use of this method requires that we have first [recorded the user as being part of the experiment](#record-experiment-user).

### Enable the experiment

After all merge requests have been merged, use [`chatops`](../../ci/chatops/README.md) in the
[appropriate channel](../feature_flags/controls.md#communicate-the-change) to start the experiment for 10% of the users.
The feature flag should have the name of the experiment with the `_experiment_percentage` suffix appended.
For visibility, please also share any commands run against production in the `#s_growth` channel:

  ```shell
  /chatops run feature set signup_flow_experiment_percentage 10
  ```

  If you notice issues with the experiment, you can disable the experiment by removing the feature flag:

  ```shell
  /chatops run feature delete signup_flow_experiment_percentage
  ```

### Testing and test helpers

#### RSpec

Use the following in RSpec to mock the experiment:

```ruby
context 'when the experiment is active' do
  before do
    stub_experiment(signup_flow: true)
  end

  context 'when the user is in the experimental group' do
    before do
      stub_experiment_for_user(signup_flow: true)
    end

    it { is_expected.to do_experimental_thing }
  end

  context 'when the user is in the control group' do
    before do
      stub_experiment_for_user(signup_flow: false)
    end

    it { is_expected.to do_control_thing }
  end
end
```

#### Jest

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
