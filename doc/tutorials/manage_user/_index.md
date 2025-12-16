---
stage: none
group: Tutorials
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Set up your organization'
description: Setup, configuration, onboarding, and organization structure.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial will teach you how to set up and manage your company's
GitLab organization by:

- Creating groups, subgroups, and projects
- Assigning different roles to group members in these groups, subgroups, and projects

In this tutorial, you are the IT administrator of a small software company. This
company uses GitLab and is divided into marketing, sales, and development divisions.

You have already set up the marketing and sales organizations. In this tutorial,
you will set up the software development organization. This organization has the
following permanent employees:

- One IT administrator: You.
- One product manager: Alex Smith.
- One engineering manager: Blake Wang.
- Three software developers: Charlie Devi, Devon Ivanov, and Evan Kim.
- One UX designer: Frankie Ali.
- One technical writer: Grayson Garcia.
- One contractor content strategist: Hunter Silva.

You're going to create:

- The software development organization.
- Groups, subgroups, and projects to manage work.
- Users to add to the groups and projects and assign roles to those users.
- A project in the organization for a specific piece of work, and add users to that project.

## Before you begin

- Make sure you have administrator access to GitLab Self-Managed.

## Create the organization parent group and subgroups

First, you'll create a group called Development. The Development group will serve
as the parent group for the whole
software development organization.

To create the Development group:

1. Open GitLab Self-Managed.
1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New group**.
1. Select **Create group**.
1. In **Group name**, enter `Development`.
1. Under **Group URL**, enter `development-group`. You'll see a message
   saying "Group path is available". The group URL is used for the namespace.
   A namespace provides a place to organize your related projects.
1. Under **Visibility level**, select **Private**. This way, any subgroups of
   this group must be private as well.
1. Under **Who will be using this group?**, select **My company or team**.
1. In the **What will you use this group for?** dropdown list, select **I want to store my code**.
1. Do not invite any GitLab members or other users to join the group yet.
1. Select **Create group**.

You have created the parent group for your organization. Next, you will create subgroups.

## Create the organization subgroups

For this tutorial, we assume that Development is organized into the following
working areas:

- Product Management
- Engineering
- User Experience
  - UX Design
  - Technical Writing

Now, you will create subgroups to reflect this organization structure.

Subgroups and projects must have visibility settings that are at least as restrictive as the visibility setting of their parent group.
For example, you cannot have a private parent group and a public subgroup.

To create your organization subgroups:

1. On the top bar, select **Search or go to**.
1. Select **View all my groups**.
1. Select **Development**. You should see an **Owner** label next to the group
   name as you have the Owner role.
1. On the parent group's overview page, select **Create subgroup**.
1. In **Subgroup name**, enter `Product Management`.
1. The **Subgroup slug** is automatically completed with **product-management**.
   Do not change this field.
1. For **Visibility level**, you can only select **Private** because the parent
   group, Development, is also private.
1. Select **Create subgroup**.
1. Repeat these steps for the following subgroups:
   - `Engineering`
   - `User Experience`

Next, create UX Design and Technical Writing subgroups. These subgroups will be nested
under the User Experience subgroup:

1. On the top bar, select **Search or go to**.
1. Select **View all my groups**.
1. Select **Development**.
1. Under the **Subgroups and projects** tab, select **User Experience**.
1. On the **User Experience** overview page, select **Create subgroup**.
1. In **Subgroup name**, enter `UX Design`.
1. Select **Create subgroup**.
1. Repeat these steps for the Technical Writing subgroup.

You have now created the subgroups for your organization. Next, you will create users
for the organization.

## Create the users for your organization

You will now manually create the users for your organization. These users are test
users. To create the first test user, Alex Smith:

1. In the upper-right corner, select **Admin**.
1. Select **Overview** > **Users**.
1. Select **New user**.
1. Complete the required fields:
   - **Name**: `Alex Smith`
   - **Username**: `alexsmith`
   - **Email**: `alexsmith@example.com`
   - Leave all other fields as is.
1. Select **Create user**.

For real users, a reset link is sent to the user's email, and that user is forced
to set their password on first sign in. However, as this user is a test user with
a fake email, you must set the user's password without using the email confirmation.

### Set the test user's password

After you create the user, you will be directed to
the user's overview page. Alternatively, in the left sidebar,
you can select **Users** and search for the user.

After you select the user:

1. Select **Edit**.
1. Complete the **Password** and **Password confirmation** fields.
1. Select **Save changes**.

You have created the first test user. Now, repeat these steps for the other users:

| Name             | Username        | Email |
|------------------|-----------------|-------|
| `Blake Wang`     | `blakewang`     | `blakewang@example.com` |
| `Charlie Devi`   | `charliedevi`   | `charliedevi@example.com` |
| `Devon Ivanov`   | `devonivanov`   | `devonivanov@example.com` |
| `Evan Kim`       | `evankim`       | `evankim@example.com` |
| `Frankie Ali`    | `frankieali`    | `frankieali@example.com` |
| `Grayson Garcia` | `graysongarcia` | `graysongarcia@example.com` |
| `Hunter Silva`   | `huntersilva`   | `huntersilva@example.com` |

You have created the users for your organization. Next, you will add these users
to the different groups and subgroups.

## Add users to the group and subgroups

You can give users access to all projects in a group by adding them to that group.

First, you will add all the users to the parent group, Development.

1. On the top bar, select **Search or go to** and find the **Development** group.
1. Select **Manage** > **Members**.
1. Select **Invite members**.
1. In the **Username, name or email address** dropdown list, select `Alex Smith`.
1. In the **Select maximum role** dropdown list, select **Owner**.
1. Leave **Access expiration date** blank.
1. Select **Invite**.
1. Repeat this process for the following users:

   | User           | Role       | Access expiration date |
   |----------------|------------|------------------------|
   | Blake Wang     | Maintainer | Leave blank            |
   | Charlie Devi   | Developer  | Leave blank            |
   | Devon Ivanov   | Developer  | Leave blank            |
   | Evan Kim       | Developer  | Leave blank            |
   | Frankie Ali    | Reporter   | Leave blank            |
   | Grayson Garcia | Reporter   | Leave blank            |
   | Hunter Silva   | Guest      | `2025-12-31`           |

   You can invite multiple users at the same time if they have the same role and
   access expiration date.

### Confirm that everything is set up correctly

On the **Group Members** page of the Development group and all subgroups, check
the membership of these groups.

- The **Source** is the origin of the user's membership of this group. The added members are direct members because
  you added them directly to the group.
- The **Role** is the added members' highest level of access they are allowed to have in this group.
  You can select the role to change the added members' roles in this group.

All the users you have added as parent group members are also members of all the
subgroups with the same role.

#### Filter a subgroup on membership type

You can filter a subgroup to show which users are direct members of that subgroup,
and which members have inherited membership of that subgroup from the parent group.

1. On the top bar, select **Search or go to** and find the **Development** group.
1. Select the **User Experience** subgroup.
1. On the left sidebar, select **Manage** > **Members**.
1. On the **Members** page, select the **Filter members** field.
1. Select **Membership**, then select **Indirect**, and press <kbd>Return</kbd>.

You now only see the User Experience subgroup members that have inherited membership
of that subgroup. You can verify inherited members by looking at the **Source** column
of each member. It should say: `Inherited from Development`.

You want each user to only be a member of the subgroup that is associated with
their role in your organization. You decide to remove the users from the groups
and subgroups.

## Remove users from the groups and subgroups

You cannot remove the members from the subgroups directly. You can only remove
them from the parent group.

Go back to the parent group and remove everyone except Alex Smith:

1. On the top bar, select **Search or go to** and find the parent group.
1. Select **Manage** > **Members**.
1. On the member row you want to remove, select the vertical ellipsis ({{< icon name="ellipsis_v" >}})
   and then select **Remove member**.
1. In the **Remove member** confirmation dialogue, select the
   **Also remove direct user membership from subgroups and projects** checkbox.
1. Select **Remove member**.

You now have one member only in the parent group and subgroups, and that member
has the Owner role.

Next, you will add users directly to the subgroups.

## Add users to the subgroups

You will now add users directly to the different subgroups.

### Add users to the Product Management subgroup

1. On the top bar, select **Search or go to** and find the **Development** group.
1. Select the **Product Management** subgroup.
1. On the left sidebar, select **Manage** > **Members**.

Excluding you, Alex is the only member of this subgroup and is a direct member,
which is correct. However, you believe they should have the Maintainer role
instead of the Owner role.

#### Change user role in the subgroup

You cannot change their role directly on the members page. To change their role in
the subgroup, invite them to the subgroup as a Maintainer.

1. Select **Invite members**.
1. Complete the fields for the product manager, Alex Smith.
   - Give Alex the **Maintainer** role.
   - Leave **Access expiration date** blank.
1. Select **Invite**.

You will see the following message:

```plaintext
The following member couldn't be invited
Review the invite errors and try again:
- Alex Smith: Access level should be greater than or equal to Owner inherited membership from group Development
```

{{< alert type="note" >}}

You cannot give Alex a subgroup role with an access level less than their role for the subgroup's parent group,
as they have an inherited membership from the parent group.

{{< /alert >}}

You decide to keep Alex as an Owner in this subgroup as it is appropriate given
their role for the organization. Select **Cancel** to cancel this invite.

The Product Management subgroup has the correct members and roles. Next, you will
add users to the Engineering subgroup.

### Add users to the Engineering subgroup

You are now going to invite some users to the Engineering subgroup.

1. On the top bar, select **Search or go to** and find the **Development** group.
1. Select the **Engineering** subgroup.
1. On the left sidebar, select **Manage** > **Members**. The only
   members are you and Alex. Both members have the Owner role, which are inherited roles.
1. Select **Invite members**.
1. Complete the fields for the following members:

   | User         | Role       | Access expiration date |
   |--------------|------------|------------------------|
   | Blake Wang   | Maintainer | Leave blank            |
   | Charlie Devi | Developer  | Leave blank            |
   | Devon Ivanov | Developer  | Leave blank            |
   | Evan Kim     | Developer  | Leave blank            |

1. Select **Invite**.

   Blake Wang has the Maintainer role in this subgroup, in line with their responsibilities as
   engineering manager. The three developers all have the Developer role, which are
   direct roles.

1. You can change their roles directly on this subgroup's member page. Under **Role**, select `Maintainer` to change Blake Wang's role
   to an Owner for this subgroup.
1. Go back to the Development group's member page. You see that the members of the Engineering
   subgroup are not members of the parent group.

By adding users directly to the groups and subgroups they need to be members of,
you avoid the issue of users being members of groups unnecessarily. You can control
access to different groups and projects in a more precise way.

## Add users to the User Experience subgroup

The User Experience subgroup has two further nested subgroups:

- UX Design
- Technical Writing

In terms of users, UX Design should only include Frankie Ali and Hunter Silva,
and Technical Writing should only include Grayson Garcia.

If you add all three users to the User Experience subgroup, they will all be
included in both nested subgroups due to inherited permissions.

Therefore, you will add these users to the appropriate nested subgroup directly
rather than to the User Experience subgroup.

1. On the top bar, select **Search or go to** and find the **Development** group.
1. Select the **User Experience** subgroup, and then the **UX Design** subgroup.
1. On the left sidebar, select **Manage** > **Members**. You and Alex
   Smith are the only members. These are inherited roles.
1. Select **Invite members**.
1. Complete the fields and select **Invite** for the following members:

   | User         | Role       | Access expiration date |
   |--------------|------------|------------------------|
   | Frankie Ali  | Maintainer | Leave blank            |
   | Hunter Silva | Guest      | `2025-12-31`           |

1. Repeat for the **Technical Writing** subgroup:

   | User           | Role       | Access expiration date |
   |----------------|------------|------------------------|
   | Grayson Garcia | Maintainer | Leave blank            |

You have added the users to their appropriate nested subgroups. You decide that
Grayson Garcia should be in the **User Experience** subgroup as well.

### Add users to other subgroups

You can add Grayson to the **User Experience** subgroup as a specific role, while
keeping their role for the **Technical Writing** subgroup the same.

1. Go to the **User Experience** subgroup.
1. On the left sidebar, select **Manage** > **Members**. You and Alex
   Smith are the only members. These are inherited roles.
1. Select **Invite members**.
1. Invite Grayson Garcia as a Developer, a role with a lower level of permissions
   than their Maintainer role for the **Technical Writing** subgroup.

Giving Grayson the Developer role means that they do not have an
unnecessarily high level of permissions
in the User Experience subgroup.

However, due to inherited permissions, adding Grayson Garcia to the User Experience
subgroup also adds them to the UX Design nested subgroup as a Developer.

{{< alert type="note" >}}

Be mindful of inherited permissions for groups and subgroups.
Add users to a minimum number of groups and subgroups.
This approach minimizes the chance of inadvertently adding a
user to a group they do not need to be a member of.

{{< /alert >}}

1. Go to the User Experience subgroup members page.
1. Add Frankie Ali and Hunter Silva as **Reporters**. Give Hunter the same expiration date.
1. Go the Technical Writing nested subgroup.

Frankie Ali and Hunter Silva are now members of the Technical Writing subgroup
due to inherited permissions.

You have successfully set up your organization with groups, subgroups, and members.

Next, you will create a project in one of the groups for members to work on.

## Create a project

Now, let's assume that you have a piece of work that certain members of your organization
need to work on. That piece of work is for the whole organization. To organize
that work, you are going to create a project in the Development parent group, and
add different users to that project.

1. On the top bar, select **Search or go to** and find the **Development** group.
1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter `Release 2.0` as the name of your project.
   - Leave the **Project slug** field as is, which is based on the project name.
   - To modify the project's viewing and access rights for users, you can change
     the **Visibility Level**. Given that the parent group is private, the project
     can only be **Private** as well.
   - To create a `README` file so that the Git repository is initialized, has a
     default branch, and can be cloned, select the **Initialize repository with a README**
     checkbox.
   - To analyze the source code in the project for known security vulnerabilities,
     select the **Enable Static Application Security Testing (SAST)** checkbox.
   - To analyze the source code for secrets and credentials to prevent unauthorized access, select the **Enable Secret Detection** checkbox.
1. Select **Create project**.

You have now created a project in the parent group.

In this project, go to **Manage** > **Members**.

The existing members of the parent group (you and Alex) are already members of
this project. When your project belongs to a group, project members inherit
their role from the group.

Other users need to be part of this project. You will now add users
directly to the project.

## Add users to the project and parent group

1. On the top bar, select **Search or go to** and find the **Release 2.0** project.
1. On the left sidebar, select **Manage** > **Members**.
1. Select **Invite members**. Invite the following users:

   | User           | Role       | Access expiration date |
   |----------------|------------|------------------------|
   | Charlie Devi   | Maintainer | Leave blank            |
   | Frankie Ali    | Maintainer | Leave blank            |
   | Grayson Garcia | Maintainer | Leave blank            |

1. Select **Invite**.
1. Because you added these users directly to the project, you can change
   their roles on the project members page if needed. Change Grayson Garcia's role
   to **Developer** to test this out.
1. Go to the Development parent group members page. The users you just added
   to the project are not there despite the project being in the parent group.
1. Add the same users directly to the parent group with **Guest** roles. You can change
   their role directly on this page. Change Frankie's role to **Reporter**.
1. Go back to the Release 2.0 project members page. The members' project roles are
   still 2 Maintainers and 1 Developer.

You have successfully added three users who are members of subgroups to a project
in the parent group, and you gave those users specific roles in the project and
parent group.
