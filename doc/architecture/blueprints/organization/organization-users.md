---
stage: enablement
group: Tenant Scale
description: 'Organization Users'
---

# Organization Users

Users can become an Organization User in the following way:

- Organization Owners create an account on behalf of a user, and then share it with the user.

Organization Users can get access to Groups and Projects in an Organization as:

- A Group Member: this grants access to the Group and all its Projects, regardless of their visibility.
- A Project Member: this grants access to the Project, and limited access to parent Groups, regardless of their visibility.
- A Non-Member: this grants access to public and internal Groups and Projects of that Organization. To access a private Group or Project in an Organization, a User must become a Member. Internal visibility will not be available for Organization in Cells 1.0.

Organization Users can be managed in the following ways:

- As [Enterprise Users](../../../user/enterprise_user/index.md), managed by the Organization. This includes control over their User account and the ability to block the User. In the context of Cells 1.0, Organization Users will essentially function like Enterprise Users.
- As Non-Enterprise Users, managed by the default Organization. Non-Enterprise Users can be removed from an Organization, but the User keeps ownership of their User account. This will only be considered post Cells 1.0.

Enterprise Users are only available to Organizations with a Premium or Ultimate subscription. Organizations on the free tier will only be able to host Non-Enterprise Users.

## How do Users join an Organization?

Users are visible across all Organizations. This allows Users to move between Organizations. Users can join an Organization by:

1. Being invited by an Organization Owner. Because Organizations are private on Cells 1.0, only the Organization Owner can add new Users to an Organization by iniviting them to create an account.

1. Becoming a Member of a Namespace (Group, Subgroup, or Project) contained within an Organization. A User can become a Member of a Namespace by:

   - Being invited by username
   - Being invited by email address
   - Requesting access. This requires visibility of the Organization and Namespace and must be accepted by the owner of the Namespace. Access cannot be requested to private Groups or Projects.

1. Becoming an Enterprise User of an Organization. Bringing Enterprise Users to the Organization level is planned post MVC. For the Organization MVC Enterprise Users will remain at the top-level Group.

The creator of an Organization automatically becomes the Organization Owner. It is not necessary to become a User of a specific Organization to comment on or create public issues, for example. All existing Users can create and comment on all public issues.

## How do Users sign in to an Organization?

TBD

## When can Users see an Organization?

For Cells 1.0, an Organization can only be private. Private Organizations can only be seen by their Organization Users. They can only contain private Groups and Projects.

For Cells 1.5, Organizations can also be public. Public Organizations can be seen by everyone. They can contain public and private Groups and Projects.

In the future, Organizations will get an additional internal visibility setting for Groups and Projects. This will allow us to introduce internal Organizations that can only be seen by the Users it contains. This would mean that only Users that are part of the Organization will see:

- The Organization front page, instead of a 404 when navigating to the Organization URL
- Name of the Organization
- Description of the Organization
- Organization pages, such as the Activity page, Groups, Projects, and Users overview. Content of these pages will be determined by each User's access to specific Groups and Projects. For instance, private Projects would only be seen by the members of this Project in the Project overview.
- Internal Groups and Projects

As an end goal, we plan to offer the following scenarios:

| Organization visibility | Group/Project visibility | Who sees the Organization? | Who sees Groups/Projects? |
| ------ | ------ | ------ | ------ |
| public | public | Everyone | Everyone |
| public | internal | Everyone | Organization Users |
| public | private | Everyone | Group/Project members |
| internal | internal | Organization Users | Organization Users |
| internal | private | Organization Users | Group/Project members |
| private | private | Organization Users | Group/Project members |

## What can Users see in an Organization?

Users can see the things that they have access to in an Organization. For instance, an Organization User would be able to access only the private Groups and Projects that they are a Member of, but could see all public Groups and Projects. Actionable items such as issues, merge requests and the to-do list are seen in the context of the Organization. This means that a User might see 10 merge requests they created in `Organization A`, and 7 in `Organization B`, when in total they have created 17 merge requests across both Organizations.

## What is a Billable Member?

How Billable Members are defined differs between GitLabs two main offerings:

- Self-managed (SM): [Billable Members are Users who consume seats against the SM License](../../../subscriptions/self_managed/index.md#subscription-seats). Custom roles elevated above the Guest role are consuming seats.
- GitLab.com (SaaS): [Billable Members are Users who are Members of a Namespace (Group or Project) that consume a seat against the SaaS subscription for the top-level Group](../../../subscriptions/gitlab_com/index.md#how-seat-usage-is-determined). Currently, [Users with Minimal Access](../../../user/permissions.md#users-with-minimal-access) and Users without a Group count towards a licensed seat, but [that's changing](https://gitlab.com/gitlab-org/gitlab/-/issues/330663#note_1133361094).

These differences and how they are calculated and displayed often cause confusion. For both SM and SaaS, we evaluate whether a User consumes a seat against the same core rule set:

1. They are active users
1. They are not bot users
1. For the Ultimate tier, they are not a Guest

For (1) this is determined differently per offering, in terms of both what classifies as active and also due to the underlying model that we refer to (User vs Member).
To help demonstrate the various associations used in GitLab relating to Billable Members, here is a relationship diagram:

```mermaid
graph TD
        A[Group] <-.type of.- B[Namespace]
        C[Project] -.belongs to.-> A

        E[GroupMember] <-.type of.- D[Member]
        G[User] -.has many.-> F
        F -.belongs to.-> C
        F[ProjectMember] <-.type of.- D
        G -.has many.-> E -.belongs to.-> A

        GGL[GroupGroupLink] -.belongs to.->A
        PGL[ProjectGroupLink] -.belongs to.->A
        PGL -.belongs to.->C
```

GroupGroupLink is the join table between two Group records, indicating that one Group has invited the other.
ProjectGroupLink is the join table between a Group and a Project, indicating the Group has been invited to the Project.

SaaS has some additional complexity when it comes to the relationships that determine whether or not a User is considered a Billable Member, particularly relating to Group/Project membership that can often lead to confusion. An example of that are Members of a Group that have been invited into another Group or Project and therewith become billable.
There are two charts as the flow is different for each: [SaaS](https://mermaid.live/view#pako:eNqNVl1v2jAU_StXeS5M-3hCU6N2aB3SqKbSPkyAhkkuxFsSs9hpVUX899mxYxsnlOWFcH1877nnfkATJSzFaBLtcvaSZKQS8DhdlWCeijGxXBCygCeOFdzSPCfbHOGrRK9Ho2tlvUkEfcZmo97HXBCBG6AcSGuOj86ZA8No_BP5eHQNMz7HYovV8kuGyR-gOx1I3Qd9Ap-31btrtgORITxIPnBXsfoAGcWKVEn2uj4T4Z6pAPdMdKyX8t2mIG-5ex0LkCnBdO4OOrOhO-O3TDQzrkkSkN9izW-BCCUTCB-8hGU866Bl45FxKJ-GdGiDDYI7SOtOp7o0GW90rA20NYjXQxE6cWSaGr1Q2BnX9hCnIbZWc1reJAly3pisMsJ19vKEFiQHfQw5PmMenwqhPQ5Uxa-DjeAa5IJk_g3t-hvdZ8jFA8vxrpYvccfWHIA6aVmrLtMQj2rvuqPynSZYcnx8PWDzlAuZsay3MfouPJxl1c9hKFCIPedzSBuH5fV2X5FDBrT8Zadk2bbszJur_xsp9UznzZRWmIizV-Njx346X9TbPpwoVqO9xobebUZmF3gse0yk9wA-jDBkflTst2TS-EyMTcrTZmGz7hPrkG8HdChdv1n5TAWmGuxHLmXI9qgTza9aO93-TVfnobAh1M6V0VDtuk7E0w313tMUy3Swc_Tyll9VLUwMPcFxUJGBNdKYTTTwY-ByesC_qusx1Yk0bXtao9kk8Snzj8eLsX0lwqV2ujnUE5Bw7FT4g7QbQGM-4YWoXPRZ2C7BnT4TXZPSiAHFUIP3nVhGbiN3G9-OyKWsTvpSS60yMYZA5U_HtyQzdy7p7GCBon65OyXNWJwT9DSNMwF7YB3Xly1o--gqKrAqCE3l359GHa4iuQ8KXEUT-ZrijtS5WEWr8iihpBZs8Vom0WRHco5XUX1IZd9NKZETUxjr8R82ROYl) and [SM](https://mermaid.live/view#pako:eNqFk1FvwiAQx7_KhefVD-CDZo2JNdmcWe3DYpeI7alsLRgKLob0u48qtqxRx9Plz4-7-3NgSCZyJEOyLcRPtqdSwXKScnBLVyhXswrUHiGxMYSsKOimwPHnXwiCYNQAsaIKzXOm2BFh3ShrOGvjujvQghAMPrAaBCOITKRLyu9Rc9FAc6Gu9VPegVELLEKzkOILMwWhUH6yRdhCcWJilEeWXSz5VJzcqrWycWvc830rOmdwnmZ8KoU-vEnXU6-bf6noPmResdzYWxdboHDeAiHBbfqOuqifonX6Ym-CV7g8HfAhfZ0U2-2xUu-iwKm2wdg4BRoJWAUXufZH5JnqH-8ye42YpFCsbGbvRN-Tx7UmunfxqFCfvZfTNeS9AfJESpQlZbn9K6Y5lxL7KUpMydCGOZXfKUl5bTmqlYhPPCNDJTU-EX3IrZEJoztJy4tY_wJJwxFj).

## How can Users switch between different Organizations?

For Organizations in the context of Cells 1.0, Users will only be able to be part of a single Organization. If a user wants to be part of multiple Organizations, they have to join every additional Organization with a new user account.

Later, in the context of Cells 1.5, Users can utilize a [context switcher](https://gitlab.com/gitlab-org/gitlab/-/issues/411637). This feature allows easy navigation and access to different Organizations' content and settings. By clicking on the context switcher and selecting a specific Organization from the provided list, Users can seamlessly transition their view and permissions, enabling them to interact with the resources and functionalities of the chosen Organization.

## What happens when a User is deleted?

We've identified three different scenarios where a User can be removed from an Organization:

1. Removal: The User is removed from the organization_users table. This is similar to the User leaving a company, but the User can join the Organization again after access approval.
1. Banning: The User is banned. This can happen in case of misconduct but the User cannot be added again to the Organization until they are unbanned. In this case, we keep the organization_users entry and change the permission to none.
1. Deleting: The User is deleted. We assign everything the User has authored to the Ghost User and delete the entry from the organization_users table.

As part of the Organization MVC, Organization Owners can remove Organization Users. This means that the User's membership entries are deleted from all Groups and Projects that are contained within the Organization. In addition, the User entry is removed from the `organization_users` table.

Actions such as banning and deleting a User will be added to the Organization at a later point.

## Organization Non-Users

Non-Users are external to the Organization and can only access the public resources of an Organization, such as public Projects.
