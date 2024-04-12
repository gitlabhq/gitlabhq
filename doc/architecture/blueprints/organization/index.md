---
status: ongoing
creation-date: "2023-04-05"
authors: [ "@lohrc", "alexpooley" ]
coach: "@ayufan"
approvers: [ "@lohrc" ]
owning-stage: "~devops::data stores"
participating-stages: []
---

<!-- vale gitlab.FutureTense = NO -->

# Organization

This document is a work in progress and represents the current state of the Organization design.

## Glossary

- Organization: An Organization is the umbrella for one or multiple top-level Groups. Organizations are isolated from each other by default meaning that cross-Namespace features will only work for Namespaces that exist in a single Organization.
- Top-level Group: Top-level Group is the name given to the topmost Group of all other Groups. Groups and Projects are nested underneath the top-level Group.
- Cell: A Cell is a set of infrastructure components that contains multiple Organizations. The infrastructure components provided in a Cell are shared among Organizations, but not shared with other Cells. This isolation of infrastructure components means that Cells are independent from each other.
- User: An Organization has many Users. Joining an Organization makes someone a User of that Organization.
- Member: Adding a User to a Group or Project within an Organization makes them a Member. Members are always Users, but Users are not necessarily Members of a Group or Project within an Organization. For instance, a User could just have accepted the invitation to join an Organization, but not be a Member of any Group or Project it contains.
- Non-User: A Non-User of an Organization means a User is not part of that specific Organization. Non-Users are able to interact with public Groups and Projects of an Organization, and can raise issues and comment on them.

## Summary

Organizations solve the following problems:

1. Enables grouping of top-level Groups. For example, the following top-level Groups would belong to the Organization `GitLab`:
    1. `https://gitlab.com/gitlab-org/`
    1. `https://gitlab.com/gitlab-com/`
1. Allows different Organizations to be isolated. Top-level Groups of the same Organization can interact with each other but not with Groups in other Organizations, providing clear boundaries for an Organization, similar to a self-managed instance. Isolation should have a positive impact on performance and availability as things like User dashboards can be scoped to Organizations.
1. Allows integration with Cells. Isolating Organizations makes it possible to allocate and distribute them across different Cells.
1. Removes the need to define hierarchies. An Organization is a container that could be filled with whatever hierarchy/entity set makes sense (Organization, top-level Groups, etc.)
1. Enables centralized control of user profiles. With an Organization-specific user profile, administrators can control the user's role in a company, enforce user emails, or show a graphical indicator that a user is part of the Organization. An example could be adding a "GitLab employee" stamp on comments.
1. Organizations bring an on-premise-like experience to GitLab.com. The Organization admin will have access to instance-equivalent Admin Area settings with most of the configuration controlled at the Organization level.

## Motivation

### Goals

The Organization focuses on creating a better experience for Organizations to manage their GitLab experience. By introducing Organizations and [Cells](../cells/index.md) we can improve the reliability, performance and availability of GitLab.com.

- Wider audience: Many instance-level features are admin only. We do not want to lock out users of GitLab.com in that way. We want to make administrative capabilities that previously only existed for self-managed users available to our GitLab.com users as well. This also means we would give users of GitLab.com more independence from GitLab.com admins in the long run. Today, there are actions that self-managed admins can perform that GitLab.com users have to request from GitLab.com admins, for instance banning malicious actors.
- Improved UX: Inconsistencies between the features available at the Project and Group levels create navigation and usability issues. Moreover, there isn't a dedicated place for Organization-level features.
- Aggregation: Data from all Groups and Projects in an Organization can be aggregated.
- An Organization includes settings, data, and features from all Groups and Projects under the same owner (including personal Namespaces).
- Cascading behavior: Organization cascades behavior to all the Projects and Groups that are owned by the same Organization. It can be decided at the Organization level whether a setting can be overridden or not on the levels beneath.
- Minimal burden on customers: The addition of Organizations should not change existing Group and Project paths to minimize the impact of URL changes.

### Non-Goals

Due to urgency of delivering Organizations as a prerequisite for Cells, it is currently not a goal to build Organization functionality on the Namespace framework.

## Proposal

We create Organizations as a new lightweight entity, with just the features and workflows which it requires. We already have much of the functionality present in Groups and Projects, and Groups themselves are essentially already the top-level entity. It is unlikely that we need to add significant features to Organizations outside of some key settings, as top-level Groups can continue to serve this purpose at least on GitLab.com. From an infrastructure perspective, cluster-wide shared data must be both minimal (small in volume) and infrequently written.

```mermaid
graph TD
  o[Organization] -. has many .- g
  ns[Namespace] --> g[Group]
  ns[Namespace] --> pns[ProjectNamespace] -. has one .- p[Project]
  ns --> un[UserNamespace]
  g -. has many .- p
  un -. has many .- p
  ns[Namespace] -. has many .- ns[Namespace]
```

All instances would set a default Organization.

### Benefits

- No changes to URL's for Groups moving under an Organization, which makes moving around top-level Groups very easy.
- Low risk rollout strategy, as there is no conversion process for existing top-level Groups.
- The Organization becomes the key for identifying what is part of an Organization, which is on its own table for performance and clarity.

### Drawbacks

- It is unclear right now how we would avoid continuing to spend effort to build instance (or not Organization) features, in particular much of the reporting. This is not an issue on GitLab.com as top-level Groups already have this capability, however, it is a challenge on self-managed. If we introduce a built-in Organization (or just none at all) for self-managed, it seems like we would need to continue to build instance/Organization level reporting features as we would not get that for free along with the work to add to Groups.
- Billing may need to be moved from top-level Groups to the Organization level.

## Data Exploration

From an initial [data exploration](https://gitlab.com/gitlab-data/analytics/-/issues/16166#note_1353332877), we retrieved the following information about Users and Organizations:

- For the users that are connected to an organization the vast majority of them (98%) are only associated with a single organization. This means we expect about 2% of Users to navigate across multiple Organizations.
- The majority of Users (78%) are only Members of a single top-level Group.
- 25% of current top-level Groups can be matched to an organization.
  - Most of these top-level Groups (83%) are associated with an organization that has more than one top-level Group.
  - Of the organizations with more than one top-level Group the (median) average number of top-level Groups is 3.
  - Most top-level Groups that are matched to organizations with more than one top-level Group are assumed to be intended to be combined into a single organization (82%).
  - Most top-level Groups that are matched to organizations with more than one top-level Group are using only a single pricing tier (59%).
- Most of the current top-level Groups are set to public visibility (85%).
- Less than 0.5% of top-level Groups share Groups with another top-level Group. However, this means we could potentially break 76,000 existing links between top-level Groups by introducing the Organization.

Based on this analysis we expect to see similar behavior when rolling out Organizations.

## Design and Implementation Details

Cells will be rolled out in three phases: Cells 1.0, Cells 1.5 and Cells 2.0.
The Organization functionality available in each phase is described below.

### Organization MVC

#### Organizations on Cells 1.0 (FY24Q2-FY25Q2)

The Organization MVC for Cells 1.0 will contain the following functionality:

- Instance setting to allow the creation of multiple Organizations. This will be enabled by default on GitLab.com, and disabled for self-managed GitLab.
- Admin overview of Organizations. All created Organizations are listed in the Admin Area section `Organizations`.
- All existing top-level Groups on GitLab.com are part of the `default Organization`.
- Organization Owner. The creation of an Organization appoints that User as the Organization Owner. Once established, the Organization Owner can appoint other Organization Owners.
- Organization Users. A User can only be part of one Organization for Cells 1.0. A new account needs to be created for each Organization a User wants to be part of. Users can only be deleted from an Organization, but not removed.
- Organization creation form. Containing the Organization name, ID, description, and avatar. Organization settings are editable by the Organization Owner.
- Setup flow. New Users are able to create new Organizations. They can also create new top-level Groups in an Organization.
- Private visibility. Initially, Organizations can only be `private`. Private Organizations can only be seen by the Users that are part of the private Organization. They can only contain private Groups and Projects. The only exception to this is the default Organization on the Primary Cell, which is `public`, and contains all currently existing Groups and Projects on GitLab.com.
- Organization settings page with the added ability to remove an Organization. Deletion of the default Organization is prevented.
- Groups. This includes the ability to create, edit, and delete Groups, as well as a Groups overview that can be accessed by the Organization Owner and Users.
- Projects. This includes the ability to create, edit, and delete Projects, as well as a Projects overview that can be accessed by the Organization Owner and Users.
- Personal Namespaces. Users get [a personal Namespace in each Organization](../cells/impacted_features/personal-namespaces.md) they are associated with.
- User Profile. Each [User Profile will be scoped to the Organization](../cells/impacted_features/user-profile.md).
- Isolation. Organizations themselves are not fully isolated, isolation is a result of being on a Secondary Cell. We aim to complete [phase 1 of Organization isolation](https://gitlab.com/groups/gitlab-org/-/epics/11837), with the goal to `define sharding_key` and `desired_sharding_key` rules.

#### Organizations on Cells 1.5 (FY25Q3-FY25Q3)

Organizations in the context of Cells 1.5 will contain the following functionality:

- Organization Users can be part of multiple Organizations using one account. Users are able to navigate between their Organizations using an Organization switcher. Non-Enterprise Users can be removed from or leave an Organization.
- Organizations are fully isolated. We aim to complete [phase 2 of Organization isolation](https://gitlab.com/groups/gitlab-org/-/epics/11838), with the goal to implement isolation constraints.

#### Organizations on Cells 2.0 (FY25Q4-FY26Q1)

Organizations in the context of Cells 2.0 will contain the following functionality:

- Public visibility. Organizations can now also be `public`, containing both private and public Groups and Projects.
- [Users can transfer existing top-level Groups into Organizations](https://gitlab.com/groups/gitlab-org/-/epics/11711).

### Organization Access

See [Organization Users](organization-users.md).

### Roles and Permissions

Organizations will have an Owner role. Compared to Users, they can perform the following actions:

| Action | Owner | User |
| ------ | ------ | ----- |
| View Organization settings | ✓ |  |
| Edit Organization settings | ✓ |  |
| Delete Organization | ✓ |  |
| Remove Users | ✓ |  |
| View Organization front page | ✓ | ✓ |
| View Groups overview | ✓ | ✓ (1) |
| View Projects overview | ✓ | ✓ (1) |
| View Users overview | ✓ | ✓ (2) |
| View Organization activity page | ✓ | ✓ (1) |
| Transfer top-level Group into Organization if Owner of both | ✓ |  |

(1) Users can only see what they have access to.
(2) Users can only see Users from Groups and Projects they have access to.

[Roles](../../../user/permissions.md) at the Group and Project level remain as they currently are.

#### Relationship between Organization Owner and Instance Admin

Users with the (Instance) Admin role can currently [administer a self-managed GitLab instance](../../../administration/index.md).
As functionality is moved to the Organization level, Organization Owners will be able to access more features that are currently only accessible to Admins.
On our SaaS platform, this helps us in empowering enterprises to manage their own Organization more efficiently without depending on the Instance Admin, which is currently a GitLab team member.
On SaaS, we expect the Instance Admin and the Organization Owner to be different users.
Self-managed instances are generally scoped to a single organization, so in this case it is possible that both roles are fulfilled by the same person.
There are situations that might require intervention by an Instance Admin, for instance when Users are abusing the system.
When that is the case, actions taken by the Instance Admin overrule actions of the Organization Owner.
For instance, the Instance Admin can ban or delete a User on behalf of the Organization Owner.

### Routing

Today only Users, Projects, Namespaces and container images are considered routable entities which require global uniqueness on `https://gitlab.com/<path>/-/`.
Initially, Organization routes will be [unscoped](../../../development/routing.md).
Organizations will follow the path `https://gitlab.com/-/organizations/org-name/` as one of the design goals is that the addition of Organizations should not change existing Group and Project paths.

## Impact of the Organization on Other Domains

We want a minimal amount of infrequently written tables in the shared database.
If we have high write volume or large amounts of data in the shared database then this can become a single bottleneck for scaling and we lose the horizontal scalability objective of Cells.
With isolation being one of the main requirements to make Cells work, this means that existing features will mostly be scoped to an Organization rather than work across Organizations.
One exception to this are Users, which are stored in the cluster-wide shared database.
For a deeper exploration of the impact on select features, see the [list of features impacted by Cells](../cells/index.md#impacted-features).

### Alignment between Organization and Fulfillment

Fulfillment enhancements for Organizations will happen in a different timeline to the [Cells](../cells/index.md) project and should not be seen as blockers to any Cells timelines. 

For Cells 1.0, Billing remains at the top-level Group. Said otherwise, Billing will not occur at the Organization level. The guidance for Cells 1.0 is for GitLab.com SaaS customers to use a single top-level Group to keep Billing consolidated.

We are currently [evaluating future architecture designs](https://gitlab.com/gitlab-org/gitlab/-/issues/443708) (e.g. Zuora Billing Accounts being aligned to Organizations) but have yet to determine the North star direction and how/if it aligns to the Cells iterations.

### Open-source Contributions in Organizations

Several aspects of the current open-source workflow will be impacted by the introduction of Organizations.
We are conducting deeper research around this specific problem in [issue 420804](https://gitlab.com/gitlab-org/gitlab/-/issues/420804).

## Post-MVC Iterations

After the initial rollout of Organizations, the following functionality will be added to address customer needs relating to their implementation of GitLab:

1. [Organizations can invite Users](https://gitlab.com/gitlab-org/gitlab/-/issues/420166).
1. Complete [phase 3 of Organization isolation](https://gitlab.com/groups/gitlab-org/-/epics/11839), with the goal to allow customers to move existing namespaces out of the default Organization into a new Organization.
1. Internal visibility will be made available on Organizations that are part of GitLab.com.
1. Restrict inviting Users outside of the Organization.
1. Enterprise Users will be made available at the Organization level.
1. Organizations are able to ban Users.
1. Projects can be created from the Organization-level Projects overview.
1. Groups can be created from the Organization-level Groups overview.
1. Move billing from top-level Group to Organization.
1. Audit events at the Organization level.
1. Set merge request approval rules at the Organization level and cascade to all Groups and Projects.
1. Security policies at the Organization level.
1. Vulnerability Report and Dependency List at the Organization level.
1. Cascading Organization setting to enforce security scans.
1. Merge request approval policies at the Organization level.
1. Compliance frameworks.
1. [Support the agent for Kubernetes sharing at the Organization level](https://gitlab.com/gitlab-org/gitlab/-/issues/382731).

## Organization Rollout

We propose the following steps to successfully roll out Organizations:

- Phase 1: Rollout
  - Organizations will be rolled out using the concept of a `default Organization`. All existing top-level groups on GitLab.com are already part of this `default Organization`. The Organization UI is feature flagged and can be enabled for a specific set of users initially, and the global user pool at the end of this phase. This way, users will already become familiar with the concept of an Organization and the Organization UI. No features would be impacted by enabling the `default Organization`. See issue [#418225](https://gitlab.com/gitlab-org/gitlab/-/issues/418225) for more details.
- Phase 2: Temporary onboarding changes
  - New customers can create new Organizations from scratch. Top-level Groups cannot be migrated yet into a new Organization, so all content must be newly created in an Organization.
- Phase 3: Migration of existing customers
  - GitLab, the organization, will be one of the first entities to migrate into a separate Organization. We move all top-level Groups that belong to GitLab into the new GitLab Organization, including the `gitLab-org` and `gitLab-com` top-level Groups. See issue [#418228](https://gitlab.com/gitlab-org/gitlab/-/issues/418228) for more details.
  - Once top-level Group transfer from the default Organization to another Organization becomes available, existing customers can create their own Organization and migrate their top-level Groups into it. Creation of an Organization remains optional.
- Phase 4: Permanent onboarding changes
  - All new customers will only have the option to start their journey by creating a new Organization.
- Phase 5: Targeted efforts
  - Organizations are promoted, e.g. via a banner message, targeted conversations with large customers via the CSMs. Creating a separate Organization will remain a voluntary action.
  - We increase the value proposition of the Organization, for instance by moving billing to the Organization level to provide incentives for more customers to move to a separate Organization. Adoption will be monitored.

A force-option will only be considered if the we do not achieve the load distribution we are aiming for with Cells.

## Alternative Solutions

An alternative approach to building Organizations is to convert top-level Groups into Organizations. The main advantage of this approach is that features could be built on top of the Namespace framework and therewith leverage functionality that is already available at the Group level. We would avoid building the same feature multiple times. However, Organizations have been identified as a critical driver of Cells. Due to the urgency of delivering Cells, we decided to opt for the quickest and most straightforward solution to deliver an Organization, which is the lightweight design described above. More details on comparing the two Organization proposals can be found [here](https://gitlab.com/gitlab-org/tenant-scale-group/group-tasks/-/issues/56).

## Frequently Asked Questions

See [Organization: Frequently Asked Questions](organization-faq.md).

## Decision Log

- 2023-05-10: [Billing is not part of the Organization MVC](https://gitlab.com/gitlab-org/gitlab/-/issues/406614#note_1384055365)
- 2023-05-15: [Organization route setup](https://gitlab.com/gitlab-org/gitlab/-/issues/409913#note_1388679761)

## Links

- [Organization epic](https://gitlab.com/groups/gitlab-org/-/epics/9265)
- [Organization MVC design](https://gitlab.com/groups/gitlab-org/-/epics/10068)
- [Enterprise Users](../../../user/enterprise_user/index.md)
- [Cells blueprint](../cells/index.md)
- [Cells epic](https://gitlab.com/groups/gitlab-org/-/epics/7582)
- [Namespaces](../../../user/namespace/index.md)
- [Organization Isolation](isolation.md)
