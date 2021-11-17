<!-- Before implementing a new empty state solution, make sure to read the 
Empty State region docs in Pajamas: https://design.gitlab.com/regions/empty-states -->

## Description

<!-- Describe the solution you're proposing for your empty state region. 
Include links to user research (if applicable). -->

## Location

<!-- Provide a link and location of the new empty state solution. 
For example: https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues -->

## Use case

<!-- What is the use case for the solution you're proposing? 
Read the Empty State docs and select the use case below: https://design.gitlab.com/regions/empty-states -->

- [ ] Blank content
- [ ] Empty search results
- [ ] Configuration required
- [ ] Higher tier

## Checklist

<!-- Follow the steps below that correspond with the use case selected above. 
Follow the steps to complete this issue -->

### Blank content

- [ ] The solution follows the `Blank content` specifications [in Pajamas](https://design.gitlab.com/regions/empty-states#blank-content).
- [ ] Follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking. 

### Empty search results

- [ ] The solution follows the `Empty search results` specifications [in Pajamas](https://design.gitlab.com/regions/empty-states#empty-search-results).
- [ ] Follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking. 

### Configuration required

- [ ] The solution follows the `Configuration required` specifications [in Pajamas](https://design.gitlab.com/regions/empty-states#configuration-required).
- [ ] Ask a [Growth product manager or Designer](https://about.gitlab.com/handbook/engineering/development/growth/#stable-counterparts) to review your solution.
- [ ] Is your solution introducing a new empty states or modifying an existing one?
   - [ ] Introducing a new empty state: Follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking. 
   - [ ] Modifying an existing empty state: Follow the [`Experimentation` process](#experimentation) below. _Note_: If the empty state you want to replace hasn't been updated in a long time, doesn't pitch the value of the feature, or does not contain a next step action CTA,  then we recommend you skip the experimentation process to implement and add tracking to your new empty state.

<!-- IF experimentation -->
#### Experimentation

- [ ] Collaborate with a [Growth product manager](https://about.gitlab.com/handbook/engineering/development/growth/#stable-counterparts) to help you determine if you can validate your solution through an experiment on SaaS. 
- [ ] If an experiment is possible, create an issue using the [experiment idea template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Experiment%20Idea) and follow the template intructions. Otherwise, follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking.
- [ ] Ask a [Growth product manager or Designer](https://about.gitlab.com/handbook/engineering/development/growth/#stable-counterparts) to review your experiment set-up. 
- [ ] Implement and monitor the experiment following the [implementation guide](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/experiment_guide/gitlab_experiment.md#implement-an-experiment).
- [ ] Review and discuss the findings.
- [ ] Add the findings to the [Growth experimentation knowledge](https://about.gitlab.com/direction/growth/#growth-experiments-knowledge-base---concluded-experiments).

### Higher tier

- [ ] The solution follows the `Higher tier` specifications [in Pajamas](https://design.gitlab.com/regions/empty-states#higher-tier).
- [ ] Ask a Product Manager or Designer from the [Conversion group](https://about.gitlab.com/handbook/engineering/development/growth/conversion/#group-members) to review your solution. 
- [ ] Is your solution introducing a new empty states or modifying an existing one?
   - [ ] Introducing a new empty state: follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking. 
   - [ ] Modifying an existing empty state, follow the [`Experimentation` process](#experimentation) below.

<!-- IF experimentation -->
#### Experimentation

- [ ] Collaborate with a [Growth product manager](https://about.gitlab.com/handbook/engineering/development/growth/#stable-counterparts) to help you determine if you can validate your solution through an experiment on SaaS. 
- [ ] If an experiment is possible, create an issue using the [experiment idea template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Experiment%20Idea) and follow the template intructions. Otherwise, follow the instructions from the [`After merge` section](#after-merge) below to add Snowplow tracking.
- [ ] Add a ~"Category:Conversion Experiment" label to the experiment idea issue.
- [ ] Ask a Product Manager or Designer from the [Conversion group](https://about.gitlab.com/handbook/engineering/development/growth/conversion/#group-members) to review your experiment set-up. 
- [ ] Implement and monitor the experiment following the [implementation guide](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/experiment_guide/gitlab_experiment.md#implement-an-experiment) .
- [ ] Review and discuss the findings.
- [ ] Add the findings to the [Growth experimentation knowledge](https://about.gitlab.com/direction/growth/#growth-experiments-knowledge-base---concluded-experiments).


## After merge

- [ ] Use the `Snowplow event tracking` [issue template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Snowplow%20event%20tracking) and open an issue to add Snowplow event tracking to your new empty state solution. 
  - [ ] Add your ~devops:: and ~group:: labels to the new issue. 
