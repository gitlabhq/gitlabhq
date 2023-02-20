---
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
---

# Development processes

Consult these topics for information on development processes for contributing to GitLab.

## Processes

Must-reads:

- [Guide on adapting existing and introducing new components](architecture.md#adapting-existing-and-introducing-new-components)
- [Code review guidelines](code_review.md) for reviewing code and having code
  reviewed
- [Database review guidelines](database_review.md) for reviewing
  database-related changes and complex SQL queries, and having them reviewed
- [Secure coding guidelines](secure_coding_guidelines.md)
- [Pipelines for the GitLab project](pipelines/index.md)

Complementary reads:

- [Contribute to GitLab](contributing/index.md)
- [Security process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/developer.md#security-releases-critical-non-critical-as-a-developer)
- [Patch release process for developers](https://gitlab.com/gitlab-org/release/docs/blob/master/general/patch/process.md#process-for-developers)
- [Guidelines for implementing Enterprise Edition features](ee_features.md)
- [Adding a new service component to GitLab](adding_service_component.md)
- [Guidelines for changelogs](changelog.md)
- [Dependencies](dependencies.md)
- [Danger bot](dangerbot.md)
- [Requesting access to ChatOps on GitLab.com](chatops_on_gitlabcom.md#requesting-access) (for GitLab team members)

### Development guidelines review

When you submit a change to the GitLab development guidelines, who
you ask for reviews depends on the level of change.

#### Wording, style, or link changes

Not all changes require extensive review. For example, MRs that don't change the
content's meaning or function can be reviewed, approved, and merged by any
maintainer or Technical Writer. These can include:

- Typo fixes.
- Clarifying links, such as to external programming language documentation.
- Changes to comply with the [Documentation Style Guide](documentation/index.md)
  that don't change the intent of the documentation page.

#### Specific changes

If the MR proposes changes that are limited to a particular stage, group, or team,
request a review and approval from an experienced GitLab Team Member in that
group. For example, if you're documenting a new internal API used exclusively by
a given group, request an engineering review from one of the group's members.

After the engineering review is complete, assign the MR to the
[Technical Writer associated with the stage and group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments)
in the modified documentation page's metadata.
If the page is not assigned to a specific group, follow the
[Technical Writing review process for development guidelines](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines).

#### Broader changes

Some changes affect more than one group. For example:

- Changes to [code review guidelines](code_review.md).
- Changes to [commit message guidelines](contributing/merge_request_workflow.md#commit-messages-guidelines).
- Changes to guidelines in [feature flags in development of GitLab](feature_flags/index.md).
- Changes to [feature flags documentation guidelines](documentation/feature_flags.md).

In these cases, use the following workflow:

1. Request a peer review from a member of your team.
1. Request a review and approval of an Engineering Manager (EM)
   or Staff Engineer who's responsible for the area in question:

   - [Frontend](https://about.gitlab.com/handbook/engineering/frontend/)
   - [Backend](https://about.gitlab.com/handbook/engineering/)
   - [Database](https://about.gitlab.com/handbook/engineering/development/database/)
   - [User Experience (UX)](https://about.gitlab.com/handbook/product/ux/)
   - [Security](https://about.gitlab.com/handbook/security/)
   - [Quality](https://about.gitlab.com/handbook/engineering/quality/)
     - [Engineering Productivity](https://about.gitlab.com/handbook/engineering/quality/engineering-productivity/)
   - [Infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
   - [Technical Writing](https://about.gitlab.com/handbook/product/ux/technical-writing/)

   You can skip this step for MRs authored by EMs or Staff Engineers responsible
   for their area.

   If there are several affected groups, you may need approvals at the
   EM/Staff Engineer level from each affected area.

1. After completing the reviews, consult with the EM/Staff Engineer
   author / approver of the MR.

   If this is a significant change across multiple areas, request final review
   and approval from the VP of Development, the DRI for Development Guidelines,
   @clefelhocz1.

1. After all approvals are complete, assign the MR to the
   [Technical Writer associated with the stage and group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments)
   in the modified documentation page's metadata.
   If the page is not assigned to a specific group, follow the
   [Technical Writing review process for development guidelines](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines).
   The Technical Writer may ask for additional approvals as previously suggested before merging the MR.

### Reviewer values

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57293) in GitLab 14.1.

As a reviewer or as a reviewee, make sure to familiarize yourself with
the [reviewer values](https://about.gitlab.com/handbook/engineering/workflow/reviewer-values/) we strive for at GitLab.

## Language-specific guides

### Go guides

- [Go Guidelines](go_guide/index.md)

### Shell Scripting guides

- [Shell scripting standards and style guidelines](shell_scripting_guide/index.md)
