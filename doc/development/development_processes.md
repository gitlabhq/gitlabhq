---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Development processes
---

Consult these topics for information on development processes for contributing to GitLab.

## Processes

Must-reads:

- [Guide on adapting existing and introducing new components](architecture.md#adapting-existing-and-introducing-new-components)
- [Code review guidelines](code_review.md) for reviewing code and having code
  reviewed
- [Database review guidelines](database_review.md) for reviewing
  database-related changes and complex SQL queries, and having them reviewed
- [Secure coding guidelines](secure_coding_guidelines.md)
- [Pipelines for the GitLab project](pipelines/_index.md)
- [Avoiding required stops](avoiding_required_stops.md)

Complementary reads:

- [Contribute to GitLab](contributing/_index.md)
- [Security process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md)
- [Patch release process for developers](https://gitlab.com/gitlab-org/release/docs/-/tree/master/general/patch)
- [Guidelines for implementing Enterprise Edition features](ee_features.md)
- [Adding a new service component to GitLab](adding_service_component.md)
- [Guidelines for changelogs](changelog.md)
- [Dependencies](dependencies.md)
- [Danger bot](dangerbot.md)
- [Requesting access to ChatOps on GitLab.com](chatops_on_gitlabcom.md#requesting-access) (for GitLab team members)

### Development guidelines review

For changes to development guidelines, request review and approval from an experienced GitLab Team Member.

For example, if you're documenting a new internal API used exclusively by
a given group, request an engineering review from one of the group's members.

Small fixes, like typos, can be merged by any user with at least the Maintainer role.

#### Broader changes

Some changes affect more than one group. For example:

- Changes to [code review guidelines](code_review.md).
- Changes to [commit message guidelines](contributing/merge_request_workflow.md#commit-messages-guidelines).
- Changes to guidelines in [feature flags in development of GitLab](feature_flags/_index.md).
- Changes to [feature flags documentation guidelines](documentation/feature_flags.md).

In these cases, use the following workflow:

1. Request a peer review from a member of your team.
1. Request a review and approval of an Engineering Manager (EM)
   or Staff Engineer who's responsible for the area in question:

   - [Frontend](https://handbook.gitlab.com/handbook/engineering/frontend/)
   - [Backend](https://handbook.gitlab.com/handbook/engineering/)
   - [Database](https://handbook.gitlab.com/handbook/engineering/development/database/)
   - [User Experience (UX)](https://handbook.gitlab.com/handbook/product/ux/)
   - [Security](https://handbook.gitlab.com/handbook/security/)
   - [Quality](https://handbook.gitlab.com/handbook/engineering/quality/)
     - [Engineering Productivity](https://handbook.gitlab.com/handbook/engineering/infrastructure/engineering-productivity/)
   - [Infrastructure](https://handbook.gitlab.com/handbook/engineering/infrastructure/)

   You can skip this step for MRs authored by EMs or Staff Engineers responsible
   for their area.

   If there are several affected groups, you may need approvals at the
   EM/Staff Engineer level from each affected area.

1. After completing the reviews, consult with the EM/Staff Engineer
   author / approver of the MR.

   If this is a significant change across multiple areas, request final review
   and approval from the VP of Development, who is the DRI for development guidelines.

Any Maintainer can merge the MR.

#### Technical writing reviews

If you would like a review by a technical writer, post a message in the `#docs` Slack channel.
Technical writers do not need to review the content, however, and any Maintainer
other than the MR author can merge.

### Reviewer values

As a reviewer or as a reviewee, make sure to familiarize yourself with
the [reviewer values](https://handbook.gitlab.com/handbook/engineering/workflow/reviewer-values/) we strive for at GitLab.

Also, any doc content should follow the [Documentation Style Guide](documentation/_index.md).

## Language-specific guides

### Go guides

- [Go Guidelines](go_guide/_index.md)

### Shell Scripting guides

- [Shell scripting standards and style guidelines](shell_scripting_guide/_index.md)

## Clear written communication

While writing any comment in an issue or merge request or any other mode of communication,
follow [IETF standard](https://www.ietf.org/rfc/rfc2119.txt) while using terms like
"MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT","RECOMMENDED", "MAY",
and "OPTIONAL".

This ensures that different team members from different cultures have a clear understanding of
the terms being used.
