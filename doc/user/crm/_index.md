---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Customer relations management (CRM)
description: Customer management, organizations, contacts, and permissions.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2256) in GitLab 14.6 [with a flag](../../administration/feature_flags/_index.md) named `customer_relations`. Disabled by default.
- In GitLab 14.8 and later, you can [create contacts and organizations only in top-level groups](https://gitlab.com/gitlab-org/gitlab/-/issues/350634).
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/346082) in GitLab 15.0.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/346082) in GitLab 15.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

{{< /history >}}

> [!note]
> This feature is not under active development, but
> [community contributions](https://about.gitlab.com/community/contribute/) are welcome.
> To determine if the feature meets your needs, see the open work items in [epic 5323](https://gitlab.com/groups/gitlab-org/-/epics/5323).

With customer relations management (CRM) you can create a record of contacts
(individuals) and organizations (companies) and relate them to work items.

By default, contacts and organizations can only be created for top-level groups.
To create contacts and organizations in other groups, [assign the group as a contact source](#configure-the-contact-source).

You can use contacts and organizations to tie work to customers for billing and reporting purposes.
For more information about what is planned for the future, see [issue 2256](https://gitlab.com/gitlab-org/gitlab/-/issues/2256).

## Permissions

| Permission                         | Guest | Planner | Group Reporter | Group Developer, Maintainer, and Owner |
|------------------------------------|-------|---------|----------------|----------------------------------------|
| View contacts/organizations        |       | ✓       | ✓              | ✓                                      |
| View work item contacts            |       | ✓       | ✓              | ✓                                      |
| Add/remove work item contacts      |       | ✓       | ✓              | ✓                                      |
| Create/edit contacts/organizations |       |         |                | ✓                                      |

## Enable customer relations management (CRM)

{{< history >}}

- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108378) in GitLab 16.9.

{{< /history >}}

Customer relations management features are enabled at the group level. If your
group also contains subgroups, and you want to use CRM features in the subgroup,
CRM features must also be enabled for the subgroup.

To enable customer relations management in a group or subgroup:

1. In the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Select **Customer relations is enabled**.
1. Select **Save changes**.

## Configure the contact source

{{< history >}}

- [Available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167475) in GitLab 17.6.

{{< /history >}}

By default, contacts are sourced from a work item's top-level group.

The contact source for a group will apply to all subgroups,
unless they have a contact source configured.

To configure the contact source for a group or subgroup:

1. In the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand the **Permissions and group features** section.
1. Select **Contact source** > **Search for a group**.
1. Select the group from which you wish to source contacts.
1. Select **Save changes**.

## Contacts

### View contacts linked to a group

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To view a group's contacts:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.

### Create a contact

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the group.

To create a contact:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. Select **New contact**.
1. Complete all required fields.
1. Select **Create new contact**.

You can also [create](../../api/graphql/reference/_index.md#mutationcustomerrelationscontactcreate)
contacts using the GraphQL API.

### Edit a contact

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the group.

To edit an existing contact:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. Next to the contact you wish to edit, select **Edit** ({{< icon name="pencil" >}}).
1. Edit the required fields.
1. Select **Save changes**.

You can also [edit](../../api/graphql/reference/_index.md#mutationcustomerrelationscontactupdate)
contacts using the GraphQL API.

#### Change the state of a contact

Each contact can be in one of two states:

- **Active**: contacts in this state can be added to a work item.
- **Inactive**: contacts in this state cannot be added to a work item.

To change the state of a contact:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. Next to the contact you wish to edit, select **Edit** ({{< icon name="pencil" >}}).
1. Select or clear the **Active** checkbox.
1. Select **Save changes**.

## Organizations

### View organizations

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To view a group's organizations:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. In the upper right, select **Organizations**.

### Create an organization

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the group.

To create an organization:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. In the upper right, select **Organizations**.
1. Select **New organization**.
1. Complete all required fields.
1. Select **Create new organization**.

You can also [create](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationcreate)
organizations using the GraphQL API.

### Edit an organization

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the group.

To edit an existing organization:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. In the upper right, select **Organizations**.
1. Next to the organization you wish to edit, select **Edit** ({{< icon name="pencil" >}}).
1. Edit the required fields.
1. Select **Save changes**.

You can also [edit](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationupdate)
organizations using the GraphQL API.

## Tickets

If you use [Service Desk](../project/service_desk/_index.md) and create tickets from emails,
tickets are linked to contacts matching the email addresses in the sender and CC of the email.

### View work items linked to a contact

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To view a contact's work items, select a contact from the work item sidebar, or:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. Next to the contact whose work items you wish to view, select **View work items** ({{< icon name="work-items" >}}).

### View work items linked to an organization

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To view an organization's work items:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Plan** > **Customer relations**.
1. In the upper right, select **Organizations**.
1. Next to the organization whose work items you wish to view, select **View work items** ({{< icon name="work-items" >}}).

### View contacts linked to a work item

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

You can view contacts associated with a work item in the right sidebar.

To view a contact's details, hover over the contact's name.

You can also view work item contacts using the
[GraphQL](../../api/graphql/reference/_index.md#mutationcustomerrelationsorganizationcreate)
API.

### Add contacts to a work item

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To add [active](#change-the-state-of-a-contact) contacts to a work item use the [`/add_contacts` quick action](../project/quick_actions.md#add_contacts) with `[contact:address@example.com]`.

You can also add, remove, or replace work item contacts using the
[GraphQL](../../api/graphql/reference/_index.md#mutationissuesetcrmcontacts)
API.

### Remove contacts from a work item

Prerequisites:

- You must have the Planner, Reporter, Developer, Maintainer, or Owner role for the group.

To remove contacts from a work item use the [`/remove_contacts` quick action](../project/quick_actions.md#remove_contacts) with `[contact:address@example.com]`.

You can also add, remove, or replace work item contacts using the
[GraphQL](../../api/graphql/reference/_index.md#mutationissuesetcrmcontacts)
API.

## Autocomplete contacts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2256) in GitLab 14.8 [with a flag](../../administration/feature_flags/_index.md) named `contacts_autocomplete`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/352123) in GitLab 15.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/352123) in GitLab 15.2. [Feature flag `contacts_autocomplete`](https://gitlab.com/gitlab-org/gitlab/-/issues/352123) removed.

{{< /history >}}

When you use the `/add_contacts` quick action, follow it with `[contact:` and an autocomplete list with the [active](#change-the-state-of-a-contact) contacts appears:

```plaintext
/add_contacts [contact:
```

When you use the `/remove_contacts` quick action, follow it with `[contact:` and an autocomplete list with the contacts added to the work item appears:

```plaintext
/remove_contacts [contact:
```

## Moving objects with CRM entries

When you move a work item or project and the **parent group contact source matches**,
work items retain their contacts.

When you move a work item or project and the **parent group contact source changes**,
work items lose their contacts.

When you move a group with a [contact source configured](#configure-the-contact-source)
or its **contact source remains unchanged**,
work items retain their contacts.

When you move a group and its **contact source changes**:

- All unique contacts and organizations are migrated to the new top-level group.
- Contacts that already exist (by email address) are deemed duplicates and deleted.
- Organizations that already exist (by name) are deemed duplicates and deleted.
- All work items retain their contacts or are updated to point at contacts with the same email address.

If you do not have permission to create contacts and organizations in the new
top-level group, the group transfer fails.
