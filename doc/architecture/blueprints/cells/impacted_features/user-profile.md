---
stage: enablement
group: Tenant Scale
description: 'Cells: User Profile'
---

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Cells: User Profile

The existing User Profiles will initially be scoped to an Organization. Long-term, we should consider aggregating parts of the User activity across Organizations to enable Users a global view of their contributions.

## 1. Definition

Each GitLab account has a [User Profile](../../../../user/profile/index.md), which contains information about the User and their GitLab activity.

## 2. Data flow

## 3. Proposal

User Profiles will be scoped to an Organization. We follow the same pattern as is used for `Your Work`, meaning that profiles are always seen in the context of an Organization.

- User Profile URLs will reference the Organization with the following URL structure `/-/organizations/<organization>/username`.
- Users can set a Home Organization as their main Organization.
- The default User Profile URL `/<username>` will refer to the user's Home Organization, or the default Organization if the user's Home Organization is not set.
- Users who do not exist in the database at all display a 404 not found error when trying to access their User Profile.
- User who haven't contributed to an Organization display their User Profile with an empty state.
- When displaying a User Profile empty state, if the profile has a Home Organization set to another Organization, we display a call-to-action allowing navigation to the main Organization.
- Breadcrumbs on the User Profile will present as `[Organization Name] / [Username]`.

See [issue #411931](https://gitlab.com/gitlab-org/gitlab/-/issues/411931) for design proposals.

## 4. Evaluation

We expect the [majority of Users to perform most of their activity in one single Organization](../../organization/index.md#data-exploration).
This is why we deem it acceptable to scope the User Profile to an Organization at first.
More discovery is necessary to understand which aspects of the current User Profile are relevant to showcase contributions in a global context.

## 4.1. Pros

- Viewing a User Profile scoped to an Organization allows you to focus on contributions that are most relevant to your Organization, filtering out the User's other activities.
- Existing User Profile URLs do not break.

## 4.2. Cons

- Users will lose the ability to display their entire activity, which may lessen the effectiveness of using their User Profile as a resume of achievements when working across multiple Organizations.
