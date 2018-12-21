---
description: How to improve GitLab's documentation.
---

# Other documentation updates

Anyone can contribute a merge request or create an issue for GitLab's documentation.

This page covers the process for general contributions to GitLab's docs (other than those which arise from release-related feature updates) can be found on the documentation guidelines page under [other documentation contributions](index.md#other-documentation-contributions).

## Role of Support in GitLab Documentation

GitLab support engineers are key contributors to GitLab docs. They should regularly update docs when handling support cases, where a doc update would enable users to accomplish tasks successfully on their own in the future, preventing problems and the need to contact Support.

Support and others should use a docs-first approach; rather than directly responding to a customer with a solution, where possible/applicable, first produce an MR for a new or updated doc and then link it in the customer communication / forum reply. If the MR can get merged immediately, even better—just link to the live doc instead.

Generally, support engineers can contribute to docs in the same way as other improvements are made, but this section contains additional Support-specific tips.

### Content: what belongs in the docs

In docs, we share any and all helpful info/processes/tips with customers, but warn them in specific terms about the potential ramifications of any mentioned actions. There is no reason to withhold 'risky' steps and store them in another location; simply include them along with the rest of the docs, with all necessary detail including specific warnings and caveats.

A `Troubleshooting` section in doc pages is part of the default [template](structure.md) for a new page, and can freely be added to any page.

These guidelines help toward the goal of having every user's search of documentation yield a useful result.

### Who can merge

Who can and should merge depends on the type of update.

- **If a simple troubleshooting item, minor correction, or other added note/caveat**, and if the content is known by the author to be accurate or has been reviewed by SME, it can be merged by anyone with master permissions (e.g. a Support Manager). However, requests for technical writer review or assistance are always welcome.

- **If creating/deleting/moving a page or page subsection, or other larger doc updates, including more extensive troubleshooting steps**, we require a technical writer review. However, you can always link a user to your MR before it is merged.

### Other ways to help

If you have ideas for further documentation resources that would be best considered/handled by technical writers, devs, and other SMEs, please create an issue.
<!-- TODO: Update and document issue and MR description templates as part of the process. -->
