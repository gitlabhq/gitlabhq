---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Customer relations management (CRM) **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2256) in GitLab 14.6 [with a flag](../../administration/feature_flags.md) named `customer_relations`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `customer_relations`.
On GitLab.com, this feature is not available.
You should not use this feature for production environments.

With customer relations management (CRM) you can create a record of contacts
(individuals) and organizations (companies) and relate them to issues.

You can use contacts and organizations to tie work to customers for billing and reporting purposes.
To read more about what is planned for the future, see [issue 2256](https://gitlab.com/gitlab-org/gitlab/-/issues/2256).

## Contacts

To view a group's contacts:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Customer relations > Contacts**.

![Contacts list](crm_contacts_v14_6.png)

You can only [create](../../api/graphql/reference/index.md#mutationcustomerrelationscontactcreate)
or [update](../../api/graphql/reference/index.md#mutationcustomerrelationscontactupdate)
contacts using the GraphQL API.

## Organizations

To view a group's organizations:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Customer relations > Organizations**.

![Organizations list](crm_organizations_v14_6.png)

You can only [create](../../api/graphql/reference/index.md#mutationcustomerrelationsorganizationcreate)
or [update](../../api/graphql/reference/index.md#mutationcustomerrelationsorganizationupdate)
organizations using the GraphQL API.

## Issues

### View issue contacts

You can view contacts associated with an issue in the right sidebar.

To view a contact's details, hover over the contact's name.

![Issue contacts](issue_crm_contacts_v14_6.png)

You can also view issue contacts using the
[GraphQL](../../api/graphql/reference/index.md#mutationcustomerrelationsorganizationcreate)
API.

### Add or remove issue contacts

Prerequisites:

- You must have at least the [Developer role](../permissions.md#project-members-permissions) for a group.

To add contacts to an issue use the `/add_contacts`
[quick action](../project/quick_actions.md).

To remove contacts from an issue use the `/remove_contacts`
[quick action](../project/quick_actions.md).

You can also add, remove, or replace issue contacts using the
[GraphQL](../../api/graphql/reference/index.md#mutationissuesetcrmcontacts)
API.
