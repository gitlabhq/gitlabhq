<!-- Follow the documentation workflow https://docs.gitlab.com/ee/development/documentation/workflow.html -->
<!-- Additional information is located at https://docs.gitlab.com/ee/development/documentation/ -->
<!-- To find the designated Tech Writer for the stage/group, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers -->

<!-- Mention "documentation" or "docs" in the MR title -->
<!-- For changing documentation location use the "Change documentation location" template -->

## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. -->

## Author's checklist

- [ ] Follow the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide/).
- [ ] Ensure that the [product tier badge](https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#product-tier-badges) is added to doc's `h1`.
- [ ] [Request a review](https://docs.gitlab.com/ee/development/code_review.html#dogfooding-the-reviewers-feature) based on the documentation page's metadata and [associated Technical Writer](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).

To avoid having this MR be added to code verification QA issues, don't add these labels: ~"feature", ~"frontend", ~"backend", ~"bug", or ~"database"

## Review checklist

Documentation-related MRs should be reviewed by a Technical Writer for a non-blocking review, based on [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and the [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide/).

- [ ] If the content requires it, ensure the information is reviewed by a subject matter expert.
- Technical writer review items:
  - [ ] Ensure docs metadata is present and up-to-date.
  - [ ] Ensure the appropriate [labels](https://about.gitlab.com/handbook/engineering/ux/technical-writing/workflow/#labels) are added to this MR.
  - If relevant to this MR, ensure [content topic type](https://docs.gitlab.com/ee/development/documentation/structure.html) principles are in use, including:
    - [ ] The headings should be something you'd do a Google search for. Instead of `Default behavior`, say something like `Default behavior when you close an issue`.
    - [ ] The headings (other than the page title) should be active. Instead of `Configuring GDK`, say something like `Configure GDK`.
    - [ ] Any task steps should be written as a numbered list.
    - If the content still needs to be edited for topic types, you can create a follow-up issue with the ~"docs-technical-debt" label.
- [ ] Review by assigned maintainer, who can always request/require the above reviews. Maintainer's review can occur before or after a technical writer review.
- [ ] Ensure a release milestone is set.

/label ~documentation
/assign me
