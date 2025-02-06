---
stage: none
group: Tutorials
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Set up your organization'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

In GitLab, you set up and manage your company's GitLab organization by:

- Creating groups, subgroups, and projects.
- Assigning group members different roles in these groups and projects.

In this tutorial, you are the IT administrator of a small software company. This
company uses GitLab and is divided into marketing, sales, and development divisions.

You have already set up the marketing and sales organizations. In this tutorial,
you will set up the software development organization. This organization has the
following permanent employees:

- One IT administrator: You.
- One product manager: Alex Smith.
- One engineering manager: Blake Wang.
- Three software developers: Charlie Devi, Devon Ivanov, Evan Kim.
- One UX designer: Frankie Ali.
- One technical writer: Grayson Garcia.

The organization also has a contractor content strategist, Hunter Silva.

You're going to create:

1. The software development organization.
1. Groups, subgroups, and projects to manage work.
1. Users to add to the groups and projects and assign roles to those users.
1. A project in the organization for a specific piece of work, and add users to
   that project.

## Before you begin

- Make sure you have administrator access to GitLab Self-Managed.

## Create the organization parent group and subgroups

You first create a group, Development, to serve as the parent group for the whole
software development organization.

1. Open GitLab Self-Managed.
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**.
1. Select **Create group**.
1. In **Group name**, enter `Development`.
1. Enter `development-group` for the group in **Group URL**. You see a message
   saying "Group path is available". The group URL is used for the namespace.
1. For visibility level, make the group **Private**. This means any subgroups of
   this group must be private as well.
1. Personalize your GitLab experience by answering the following questions:
   - For **Role**, select **Development Team Lead**.
     This role is different to the roles that affect member permissions.
   - For **Who will be using this group?**, select **My company or team**.
   - For **What will you use this group for?**, select **I want to store my code**.
1. Do not invite any GitLab members or other users to join the group yet.
1. Select **Create group**.

> In GitLab, a namespace provides a place to organize your related projects.

You have created the parent group for your organization. Next you will create subgroups.

## Create the organization subgroups

For this tutorial, we assume that Development is organized into the following
working areas:

- Product Management.
- Engineering.
- User Experience.
  - UX Design.
  - Technical Writing.

You will now create subgroups to reflect this organization structure.

> Subgroups and projects must have visibility settings that are at least as restrictive as the visibility setting of their parent group. For example, you cannot have a private parent group and a public subgroup.

1. On the left sidebar, select **Search or go to**.
1. Select **View all my groups**.
1. Select **Development**. You should see an **Owner** label next to the group
   name as you have the Owner role.
1. On the parent group's overview page, in the upper-right corner, select **New subgroup**.
1. In **Subgroup name**, enter `Product Management`.
1. The **Subgroup slug** is automatically completed with **product-management**.
   Do not change this field.
1. For **Visibility level**, you can only select **Private** because the parent
   group, Development, is also private.
1. Select **Create subgroup**.
1. Repeat for the following subgroups:
   - `Engineering`.
   - `User Experience`.
     - `UX Design`.
     - `Technical Writing`.

UX Design and Technical Writing are subgroups nested in the User Experience subgroup.

You have now created the subgroups for your organization. Next you will create users
for the organization.

## Create the users for your organization

You will now manually create the users for your organization. These are test
users. To create the first test user, Alex Smith:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
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

1. Select the user.
1. Select **Edit**.
1. Complete the password and password confirmation fields.
1. Select **Save changes**.

You have created the first test user. Now repeat this for the other users:

| Name             | Username        | Email |
|------------------|-----------------|-------|
| `Blake Wang`     | `blakewang`     | `blakewang@example.com` |
| `Charlie Devi`   | `charliedevi`   | `charliedevi@example.com` |
| `Devon Ivanov`   | `devonivanov`   | `devonivanov@example.com` |
| `Evan Kim`       | `evankim`       | `evankim@example.com` |
| `Frankie Ali`    | `frankieali`    | `frankieali@example.com` |
| `Grayson Garcia` | `graysongarcia` | `graysongarcia@example.com` |
| `Hunter Silva`   | `huntersilva`   | `huntersilva@example.com` |

You have created the users for your organization. Next you will add these users
to the different groups and subgroups.

## Add users to the group and subgroups

You can give users access to all projects in a group by adding them to that group.

First, you will add all the users to the parent group, Development.

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select **Manage > Members**.
1. Select **Invite members**.
1. Complete the fields for the product manager, Alex Smith.
   - Give Alex the **Owner** role. The role applies to all subgroups projects
     in the group.
   - Leave **Access expiration date** blank.
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

> The **Source** is the origin of the user's membership of this group. The added members are direct members because you added them directly to the group.
>
> The **Max role** is the added members' highest level of access they are allowed to have in this group. You can use the dropdown list in this column to change the added members' roles in this group.

All the users you have added as parent group members are also members of all the
subgroups with the same role.

#### Filter a subgroup on membership type

You can filter a subgroup to show which users are direct members of that subgroup,
and which members have inherited membership of that subgroup from the parent group.

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select the **User Experience** subgroup.
1. On the left sidebar, select **Subgroup information > Members**.
1. On the **Members** page, select the **Filter members** field.
1. Select **Membership**, then select **Inherited**, and press <kbd>Return</kbd>.

You now only see the User Experience subgroup members that have inherited membership
of that subgroup.

You want each user to only be a member of the subgroup that is associated with
their role in your organization. You decide to remove the users from the groups
and subgroups.

## Remove users from the groups and subgroups

You cannot remove the members from the subgroups directly. You can only remove
them from the parent group.

Go back to the parent group and remove everyone except Alex Smith:

1. On the left sidebar, select **Search or go to** and find the parent group.
1. Select **Manage > Members**.
1. On the member row you want to remove, select the vertical ellipsis (**{ellipsis_v}**)
   and then select **Remove member**.
1. In the **Remove member** confirmation box, select the
   **Also remove direct user membership from subgroups and projects** checkbox.
1. Select **Remove member**.

You now have one member only in the parent group and subgroups, and that member
has the Owner role.

Next you will add users directly to the subgroups.

## Add users to the subgroups

You will now add users directly to the different subgroups.

### Add users to the Product Management subgroup

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select the **Product Management** subgroup.
1. On the left sidebar, select **Subgroup information > Members**.

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

> You cannot give Alex a subgroup role with an access level less than their role for the subgroup's parent group, as they have an inherited membership from the parent group.

You decide to keep Alex as an Owner in this subgroup as it is appropriate given
their role for the organization. Select **Cancel** to cancel this invite.

The Product Management subgroup has the correct members and roles. Next you will
add users to the Engineering subgroup.

### Add users to the Engineering subgroup

You are now going to invite some users to the Engineering subgroup.

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select the **Engineering** subgroup.
1. On the left sidebar, select **Subgroup information > Members**. The only
   members are you and Alex, both with the Owner role. These are inherited roles.
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
   engineering manager. The three developers all have the Developer role. These are
   direct roles.

1. You can change their roles directly on this subgroup's member page. Change Blake Wang
   to an Owner for this subgroup.
1. Go back to the Development group's member page. You see that the members of the Engineering
   subgroup are not members of the parent group.

By adding users directly to the groups and subgroups they need to be members of,
you avoid the issue of users being members of groups unnecessarily. You can control
access to different groups and projects in a more precise way.

## Add users to the User Experience subgroup

The User Experience subgroup has two further nested subgroups:

- UX Design.
- Technical Writing.

In terms of users, UX Design should only include Frankie Ali and Hunter Silva,
and Technical Writing should only include Grayson Garcia.

If you add all three users to the User Experience subgroup, they will all be
included in both nested subgroups due to inherited permissions.

Therefore, you will add these users to the appropriate nested subgroup directly
rather than to the User Experience subgroup.

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select the **User Experience** subgroup, and then the **UX Design** subgroup.
1. On the left sidebar, select **Subgroup information > Members**. You and Alex
   Smith are currently the only members. These are inherited roles.
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
1. On the left sidebar, select **Subgroup information > Members**. You and Alex
   Smith are currently the only members. These are inherited roles.
1. Select **Invite members**.
1. Invite Grayson Garcia as a Developer, a role with a lower level of permissions
   than their Maintainer role for the **Technical Writing** subgroup.

This means that Grayson Garcia does not have an unnecessarily high level of permissions
in the User Experience subgroup.

However, due to inherited permissions, adding Grayson Garcia to the User Experience
subgroup also adds them to the UX Design nested subgroup as a Developer.

> Be mindful of inherited permissions for groups and subgroups. Add users to a minimum number of groups and subgroups to minimize the chance of inadvertently adding a user to a group they do not need to be a member of.

1. Go to the User Experience subgroup members page.
1. Add Frankie Ali and Hunter Silva as **Reporters**. Give Hunter the same expiration date.
1. Go the Technical Writing nested subgroup.

Frankie Ali and Hunter Silva are now members of the Technical Writing subgroup
due to inherited permissions.

You have successfully set up your organization with groups, subgroups and members.

Next you will create a project in one of the groups for members to work on.

## Create a project

Now, let's assume that you have a piece of work that certain members of your organization
need to work on, and that piece of work is for the whole organization. To organize
that work, you are going to create a project in the Development parent group, and
add different users to that project.

1. On the left sidebar, select **Search or go to** and find the **Development** group.
1. Select **Create new** (**{plus}**) and **New project/repository**.
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
1. Select **Create project**.

You have now created a project in the parent group.

In this project, go to **Manage > Members**.

The existing members of the parent group (you and Alex) are already members of
this project because when your project belongs to a group, project members inherit
their role from the group.

There are other users that need to be part of this project. You will now add users
directly to the project.

## Add users to the project and parent group

1. On the left sidebar, select **Search or go to** and find the **Release 2.0** project.
1. On the left sidebar, select **Manage > Members**.
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
in the parent group, and given those users specific roles in the project and
parent group.
