<!-- Custom Roles documentation: See https://docs.gitlab.com/ee/user/custom_roles.html -->
<!-- Available Permissions: https://docs.gitlab.com/ee/user/custom_roles/abilities.html -->
<!-- Example of Permission Request: See https://gitlab.com/gitlab-org/gitlab/-/issues/442851 -->

## Proposed Permission

<!-- Describe the real-world use case for the permissions you want to introduce, including why you need the requested level of granularity, and why the available default roles are not sufficient.

Example: Group Owners have the ability to manage team members. This leads to organizations elevating a subset of users who need to manage these settings to Owners, so as a consequence these users can edit other group or project settings without needing to. Adding the `manage team member` custom permission will allow an organization to create a custom role, such as Developer + this permission, which reduces unneeded Owners and Maintainers in their organizations.
 -->

## Proposal and User Experience

<!-- State what actions a user with this permission can take at a group and project level. -->

| Group Actions | Project Actions |
| ------------- | --------------- |
| Actions       | Actions         |
| Actions       | Actions         |

### Views+Workflows include:

<!-- State what a user with this permission can see in terms of workflows from a UI perspective. For example, for Runners, a user can see:

Base + permission: Group-> Build -> Runners
Base + permission: Projects -> Settings > CI/CD > Runners
-->

- [ ] Base + Permission

### Impacted APIs
<!-- Include a list of API's impacted for the permission -->

#### Documentation

<!-- Permissions for Custom Roles is auto-generated. A title and description should be included for the proposal. Also if the feature has documentation, there is a "Prerequisities" section under a feature that highlight required permissions. The permission for custom role should be documented and appended next to the required default role.

Example:
- Permission Title: "Manage Variables"
- Permission Description: "Create, read, update, and delete Variables"

Prerequisites:
You must be a project member with the Maintainer role or have a [custom role](link).
-->

- [ ] Permission Title: "Manage X"
- [ ] Permission Description: "Create, read, update, and delete X"
- [ ] Update prerequisites for feature documentation. Include links to feature pages.
   
/label ~"group::authorization" ~"Category:Permissions" ~"type::feature"