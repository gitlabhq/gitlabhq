---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Experiment Guide

Experiments can be conducted by any GitLab team, most often the teams from the [Growth Sub-department](https://about.gitlab.com/handbook/engineering/development/growth/). Experiments are not tied to releases because they will primarily target GitLab.com.

Experiments will be run as an A/B test and will be behind a feature flag to turn the test on or off. Based on the data the experiment generates, the team will decide if the experiment had a positive impact and will be the new default or rolled back.

## Experiment tracking issue

Each experiment should have an [Experiment tracking](https://gitlab.com/groups/gitlab-org/-/issues?scope=all&utf8=%E2%9C%93&state=opened&label_name[]=growth%20experiment&search=%22Experiment+tracking%22) issue to track the experiment from roll-out through to cleanup/removal. Immediately after an experiment is deployed, the due date of the issue should be set (this depends on the experiment but can be up to a few weeks in the future).
After the deadline, the issue needs to be resolved and either:

- It was successful and the experiment will be the new default.
- It was not successful and all code related to the experiment will be removed.

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

### Implementation

1. Add the experiment to the `Gitlab::Experimentation::EXPERIMENTS` hash in [`experimentation.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib%2Fgitlab%2Fexperimentation.rb):

   ```ruby
   EXPERIMENTS = {
     other_experiment: {
       #...
     },
     # Add your experiment here:
     signup_flow: {
       environment: ::Gitlab.dev_env_or_com?, # Target environment, defaults to enabled for development and GitLab.com
       tracking_category: 'Growth::Acquisition::Experiment::SignUpFlow' # Used for providing the category when setting up tracking data
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

      The above will check whether the experiment is enabled and push the result to the frontend.

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

1. Track necessary events. See the [product analytics guide](../product_analytics/index.md) for details.
1. After the merge request is merged, use [`chatops`](../../ci/chatops/README.md) in the
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

### Tests and test helpers

Use the following in Jest to test the experiment is enabled.

```javascript
import { withGonExperiment } from 'helpers/experimentation_helper';

describe('given experiment is enabled', () => {
  withGonExperiment('signupFlow');

  it('should do the experimental thing', () => {
    expect(wrapper.find('.js-some-experiment-triggered-element')).toEqual(expect.any(Element));
  });
});
```
