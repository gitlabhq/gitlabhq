# Experiment Guide

Experiments will be conducted by teams from the [Growth Section](https://about.gitlab.com/handbook/engineering/development/growth/) and are not tied to releases, because they will primarily target GitLab.com.

Experiments will be run as an A/B test and will be behind a feature flag to turn the test on or off. Based on the data the experiment generates, the team decides if the experiment had a positive impact and will be the new default or rolled back.

## Follow-up issue

Each experiment requires a follow-up issue to resolve the experiment. Immediately after an experiment is deployed, the deadline of the issue needs to be set (this depends on the experiment but can be up to a few weeks in the future).
After the deadline, the issue needs to be resolved and either:

- It was successful and the experiment will be the new default.
- It was not successful and all code related to the experiment will be removed.

In either case, an outcome of the experiment should be posted to the issue with the reasoning for the decision.

## Code reviews

Since the code of experiments will not be part of the codebase for a long time and we want to iterate fast to retrieve data,the code quality of experiments might sometimes not fulfill our standards but should not negatively impact the availability of GitLab whether the experiment is running or not.
Experiments will only be deployed to a fraction of users but we still want a flawless experience for those users. Therefore, experiments still require tests.

For reviewers and maintainers: if you find code that would usually not make it through the review, but is temporarily acceptable, please mention your concerns but note that it's not necessary to change.
The author then adds a comment to this piece of code and adds a link to the issue that resolves the experiment.

## How to create an A/B test

- Add the experiment to the `Gitlab::Experimentation::EXPERIMENTS` hash in [`experimentation.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib%2Fgitlab%2Fexperimentation.rb):

  ```ruby
  EXPERIMENTS = {
    other_experiment: {
      #...
    },
    # Add your experiment here:
    sign_up_flow: {
      feature_toggle: :experimental_sign_up_flow, # Feature flag that will be used
      environment: ::Gitlab.dev_env_or_com?, # Target environment
      enabled_ratio: 0.1 # Percentage of users that will be part of the experiment. 10% of the users would be part of this experiments.
    }
  }.freeze
  ```

- Use the experiment in a controller:

  ```ruby
  class RegistrationController < Applicationcontroller
   def show
     # experiment_enabled?(:feature_name) is also available in views and helpers
     if experiment_enabled?(:sign_up_flow)
       # render the experiment
     else
       # render the original version
     end
   end
  end
  ```

- Track necessary events. See the [event tracking guide](../event_tracking/index.md) for details.
- After the merge request is merged, use [`chatops`](../../ci/chatops/README.md) to enable the feature flag and start the experiment. For visibility, please run the command in the `#s_growth` channel:

  ```
  /chatops run feature set --project=gitlab-org/gitlab experimental_sign_up_flow true
  ```

  If you notice issues with the experiment, you can disable the experiment by setting the feature flag to `false` again.
