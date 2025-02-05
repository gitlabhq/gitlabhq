---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: List branch rules for a project by using GraphQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106954) in GitLab 15.8.

You can query for branch rules in a given project by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).
- [The GitLab Development Kit (GDK)](#use-the-gdk).

## Use GraphiQL

You can use GraphiQL to list the branch rules for a project.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window.
   This query searches for a project by its full path, for example `gitlab-org/gitlab-docs`.
   It requests all configured branch rules for the project.

   ```graphql
   query {
     project(fullPath: "gitlab-org/gitlab-docs") {
       branchRules {
         nodes {
           name
           isDefault
           isProtected
           matchingBranchesCount
           createdAt
           updatedAt
           branchProtection {
             allowForcePush
             codeOwnerApprovalRequired
             mergeAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             pushAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             unprotectAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
           }
           externalStatusChecks {
             nodes {
               id
               name
               externalUrl
             }
           }
           approvalRules {
             nodes {
               id
               name
               type
               approvalsRequired
               eligibleApprovers {
                 nodes {
                   name
                 }
               }
             }
           }
         }
       }
     }
   }
   ```

1. Select **Play**.

If no branch rules are displayed, it might be because:

- No branch rules are configured.
- Your role doesn't have permission to view branch rules. Administrators have access to all resources.

## Use the GDK

Instead of requesting access, it may be easier for you to run the query in the
[GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).

1. Sign in as the default admin, `root`, with the credentials from
   [the GDK documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_commands.md#get-the-login-credentials).
1. Ensure you have some branch rules configured for the `flightjs/Flight` project.
1. In your GDK instance, open GraphiQL: `http://gdk.test:3000/-/graphql-explorer`.
1. Copy the query and paste it in the left window.
1. Replace the full path with the following path:

   ```graphql
   query {
     project(fullPath: "flightjs/Flight") {
   ```

1. Select **Play**.

## Related topics

- [GraphQL API reference](reference/_index.md)
