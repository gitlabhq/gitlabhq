---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Test cases in GitLab can help your teams create testing scenarios in their existing development platform.
type: reference
---

# Test cases **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/233479) in GitLab 13.6.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/241983) in GitLab 13.7.

Test cases in GitLab can help your teams create testing scenarios in their existing development platform.

Now your Implementation and Testing teams can collaborate better, as they no longer have to
use external test planning tools, which require additional overhead, context switching, and expense.

NOTE:
[Requirements](../../user/project/requirements/index.md) and test cases are being
[migrated to work items](https://gitlab.com/groups/gitlab-org/-/epics/5171).
[Issue 323790](https://gitlab.com/gitlab-org/gitlab/-/issues/323790) proposes to link requirements to test cases.
For more information, see [Product Stage Direction - Plan](https://about.gitlab.com/direction/plan/).

## Create a test case

Prerequisite:

- You must have at least the Reporter role.

To create a test case in a GitLab project:

1. Go to **CI/CD > Test cases**.
1. Select **New test case**. You are taken to the new test case form. Here you can enter
   the new case's title, [description](../../user/markdown.md), attach a file, and assign [labels](../../user/project/labels.md).
1. Select **Submit test case**. You are taken to view the new test case.

## View a test case

You can view all test cases in the project in the test cases list. Filter the
issue list with a search query, including labels or the test case's title.

Prerequisite:

Whether you can view an test case depends on the [project visibility level](../../user/public_access.md):

- Public project: You don't have to be a member of the project.
- Private project: You must have at least the Guest role for the project.

To view a test case:

1. In a project, go to **CI/CD > Test cases**.
1. Select the title of the test case you want to view. You are taken to the test case page.

![An example test case page](img/test_case_show_v13_10.png)

## Edit a test case

You can edit a test case's title and description.

Prerequisite:

- You must have at least the Reporter role.
- Users demoted to the Guest role can continue to edit the test cases they created
when they were in the higher role.

To edit a test case:

1. [View a test case](#view-a-test-case).
1. Select **Edit title and description** (**{pencil}**).
1. Edit the test case's title or description.
1. Select **Save changes**.

## Archive a test case

When you want to stop using a test case, you can archive it. You can [reopen an archived test case](#reopen-an-archived-test-case) later.

Prerequisite:

- You must have at least the Reporter role.

To archive a test case, on the test case's page, select **Archive test case**.

To view archived test cases:

1. Go to **CI/CD > Test cases**.
1. Select **Archived**.

## Reopen an archived test case

If you decide to start using an archived test case again, you can reopen it.

You must have at least the Reporter role.

To reopen an archived test case, on the test case's page, select **Reopen test case**.
