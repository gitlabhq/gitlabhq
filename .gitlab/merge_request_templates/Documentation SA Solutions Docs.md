<!-- Use this template for documentation updates in the /doc/solutions directory. -->

This MR Template ensures that Solutions Docs published here: https://docs.gitlab.com/ee/solutions/, follow the optimized review and approval workflow for that area rather than the normal tech writing workflow by applying appropriate labels and reviewers.

## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. -->

## Review

- [ ] I have read the [Solutions Docs Contributors Guide in the GitLab Handbook](https://handbook.gitlab.com/handbook/customer-success/solutions-architects/sa-documentation/) and believe that this contribution complies with the scope and requirements outlined there.
- [ ] Assign yourself as the **Assignee** of this MR.
- [ ] Assign the latest release for the **Milestone**. If you're not sure, [view the list of releases](https://about.gitlab.com/releases/).
- [ ] Mention the reviewers in a comment, so they're aware that the MR is ready.
- [ ] If navigation changes are needed, create an MR in the gitlab-docs project according to this documentation process. [Here is an example](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/4863).
  - [ ] If making a navigation change, list the Navigation MR here: `link to your navigation update MR`

## Merging

- [ ] Obtain approval from a member of the Solutions Documentation Approvers Group (CODEOWNERS for the Solutions directory)

When a code owner approves, they can merge.

## Troubleshooting

The pipeline will test for style and link issues. If you have issues you're unable to resolve,
view the documentation [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide/)
or ask for assistance in the #docs Slack channel.

/label ~documentation ~Solutions ~"type::maintenance" ~"maintenance::refactor" 
/assign me
/request_review @DarwinJS @jmoverley
