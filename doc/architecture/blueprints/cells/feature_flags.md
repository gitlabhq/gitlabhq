---
stage: proposal
group: Engineering Productivity
description: 'Cells: Feature Flags'
authors: [ "@skarbek" ]
coach: "@rymai"
---

<!-- vale gitlab.FutureTense = NO -->

# Feature Flags

## Summary

This document is to cover GitLab current usage and future use of Feature Flags when used in Development specifically with use on the Cells Infrastructure. Reference our development documentation for Feature Flags here:

- [Development Documentation](../../../development/feature_flags/index.md)
- [Blueprint Implementation](../feature_flags_development/index.md)
- [Blueprint Operations Proposal](../feature_flags_usage_in_dev_and_ops/index.md)

:warning: Do not confuse this with the GitLab Application feature set of [Feature Flags](../../../operations/feature_flags.md).

### Current Usage

Feature Flags play a vital role in the Development of GitLab. Chunks of code have the ability to be tested in a safe manner increasing confidence that a new feature will operate both as desired and at the scale of .com. Cells introduces a new set of challenges on top of already existing bits of technical debt related to the wide adoption of Feature Flags. Reference our existing blueprint for Feature Flags for further information: [Feature Flag Use Cases](../../blueprints/feature_flags_usage_in_dev_and_ops/index.md#feature-flag-use-cases)

### Challenges in Cells

- Discovery capabilities to understand what actors exist on which Cells
- Rollout capabilities per Cell do not exist
- Management of feature flag state is not centralized
- Expansion of Cells brings burden to Development and Operations teams

## Proposal

We will iterate on expanding our use of Feature Flags into Cells, but far slower as the Primary Cell, or the current .com Infrastructure, will still be the primary place that we can expect the majority of feature flags to be leveraged for testing. Because the migration of customers onto Cells is a goal in the future we'll certainly want to expand how we interact with Feature Flags for target actors, but we need to develop the capabilities and procedures to ensure the safety and stability of .com.

### Iteration Cells 1.0

With the ultimate goal that Cells is attempting to host more stable versions of GitLab, our first Iteration for feature flags will mostly be discovery of work to be accomplished along with prioritizing with the appropriate teams. Doing so also provides us time to think about future iterations and refine as we see fit.

The expectation here is that we'll continue to use our Primary Cell, our current infrastructure, to manage and change feature flags like we do today with no change in the behavior or the expectations by Development teams related to any Secondary Cells. Any on-going work surrounding improvements that may already be in progress should be accounted for as to prevent interference or introduce unnecessary complexity.

### Future Iterations

#### Adding Capabilities

##### Engagement on Cells

Historically, Feature Flags have the potential to mitigate incidents. For example, if a feature is behind a feature flag and enabled, but the code may not be behaving as desired, we can use this as leverage to mitigate incidents. In another example, a feature may be under heavy development and we need to gather additional information prior to enabling that feature Cluster wide. We could provide a mechanism where development teams directly engage with a Cell. In order to accomplish this, we'll need to expand the capabilities of Chatops to understand the concept of Cells as well as the ability to provide a UX for which Engineering teams can execute a command to target a Cell.

Let's use an example. Let's say we want to change the feature flag `lorem_ipsum_dolar` on Cell 7 because of an identified incident related to the code sitting behind this flag. Using the command:

> `/chatops run feature set lorem_ipsum_dolar false --cell 7`

This will reach out to Cell 7 and disable the feature flag.

##### Engagement on Actors

Feature Flags that are leveraged to gather information to assist with development may target a specific project, user, or percentage based actor. Issues exist which that make setting this across all Cells difficult. Thus, for actor based changes to feature flags, these will be limited to only the Primary Cell.

Let's use an example. Let's say we want to change feature flag `lorem_ipsum_dolar` for actor `@ayufan`. This user may be spread across 3 total Cells. Using the command:

> `/chatops run feature set lorem_ipsum_dolar ayufan`

The command only change the flag for that actor on our Primary Cell. All other cells will be ignored. We may be able to expand Chatops to be able to accept an added flag such that we could directly set the actor on a particular Cell. Doing so will require the Engineer to know which Cell an actor resides. The reason for these limitations is to account for the fact that users and projects may be spread across a multitude of Cells. Cells are also being designed such that we can migrate data from one Cell to another. Feature Flag data is stored as a setting on a Cell and thus the metadata associated with what flags are set are not part of the knowledge associated with an actor. This introduces risk that if we target an actor, and later that actor is moved, the flag would no longer be set properly. This will lead to differing behavior for a given actor, but normally these types of changes happen to internal customers to GitLab reducing risk that users will notice a behavioral change as they switch between Cells. This implementation is also simplistic, removing the need to query _some service_ which hosts the Cells and actor resides, and needing to develop a specialized rollout procedure when the resulting target may be more than a single Cell. This is discussed a bit more in the next section.

##### Engagement on Environments

Today we have the ability to set a feature flag for an entire environment. Production is one of them. This begs the question, how do we roll out feature flags to all Cells? Ideally the flag will have been well tested, but we may still need some sort of testing to validate behavior, prior to rolling the flag to all Cells.

Let's use an example. Let's say we want to enable the flag `lorem_ipsum_dolar` on all of Production. Using the command:

> `/chatops run feature set lorem_ipsum_dolar true --production`

This command will need to perform a lot of work. Firstly, it needs to gather all Cells where this feature flag exists. If the flag does not exist on any Cell, we must not change this as this introduces an consistency issue between the Engineer expectations and that of the Production environment. We may consider an override in the case we are attempting to leverage this to mitigate an incident of a deployment that is not fully completed, however. If the flag does exist across all Cells of a given environment, we then begin to roll that change out across all Cells. It would be inadvisable to change all Cells at the same time. Chatops now needs the ability to have some mechanism to make the change to a given list of Cells, wait for some signal, then proceeding to the next list of Cells. Repeating until completion. We may need a mechanism to bypass this intentionally built slow rollout if we are targeting a flag that may remediate an incident across all Cells. The Delivery team plan on using a Ring style of deployments for Cells, we may be able to leverage similar metadata to assist in rollouts for this use case.

#### Requirements

- Chatops needs the ability to talk to _some service_ to gather requisite information. This may include:
  - The listing of Cells
  - Actors assigned to a listing of Cells
- When a new Cell is brought online, we need not manage configuration for Chatops. Instead, Chatops should have automated access to new Cells. This minimizes the administrative burden whenever a Cell is newly constructed.
- Procedure refinement. We already have [existing efforts](https://gitlab.com/groups/gitlab-org/-/epics/5324) to improve various aspects of Feature Flags today. We should remain cognizant of this on-going work.
