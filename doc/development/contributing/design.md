---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Design and user interface changes
---

Follow these guidelines when contributing or reviewing design and user interface
(UI) changes. Refer to our [code review guide](../code_review.md) for broader
advice and best practices for code review in general.

The basis for most of these guidelines is [Pajamas](https://design.gitlab.com/),
GitLab design system. We encourage you to [contribute to Pajamas](https://design.gitlab.com/get-started/contributing/)
with additions and improvements.

## Merge request reviews

As a merge request (MR) author, you must:

- Include _Before_ and _After_
  screenshots (or videos) of your changes in the description, as explained in our
  [MR workflow](merge_request_workflow.md). These screenshots/videos are very helpful
  for all reviewers and can speed up the review process, especially if the changes
  are small.
- Attach the ~UX label to any merge request that has any user facing changes. This will trigger our
  Reviewer Roulette to suggest a UX [reviewer](https://handbook.gitlab.com/handbook/product/ux/product-designer/mr-reviews/#stage-group-mrs).

If you are a **team member**: We recommend assigning the Product Designer suggested by the
[Reviewer Roulette](../code_review.md#reviewer-roulette) as reviewer. [This helps us](https://handbook.gitlab.com/handbook/product/ux/product-designer/mr-reviews/#benefits) spread work evenly, improve communication, and make our UI more
consistent. If you have a reason to choose a different reviewer, add a comment to mention you assigned
it to a Product Designer of your choice.

If you are a **community contributor**: We favor choosing the Product Designer that is a
[domain expert](../code_review.md#domain-experts) in the area you are contributing, to regardless
of the Reviewer Roulette.

## Checklist

Check these aspects both when _designing_ and _reviewing_ UI changes.

### Writing

- Follow [Pajamas](https://design.gitlab.com/content/ui-text/) as the primary
  guidelines for UI text and [documentation style guide](../documentation/styleguide/_index.md)
  as the secondary.
- Use clear and consistent terminology.
- Check grammar and spelling.
- Consider help content and follow its [guidelines](https://design.gitlab.com/usability/contextual-help).
- Request review from the [appropriate Technical Writer](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments),
  indicating any specific files or lines they should review, and how to preview
  or understand the location/context of the text from the user's perspective.

### Patterns

- Consider similar patterns used in the product and justify in the issue when diverging
  from them.
- Use appropriate [components](https://design.gitlab.com/components/overview/)
  and [data visualizations](https://design.gitlab.com/data-visualization/overview/).

### Visual design

Check visual design properties using your browser's elements inspector ([Chrome](https://developer.chrome.com/docs/devtools/css/),
[Firefox](https://firefox-source-docs.mozilla.org/devtools-user/page_inspector/how_to/open_the_inspector/index.html)).

- Use recommended [colors](https://design.gitlab.com/product-foundations/color)
  and [typography](https://design.gitlab.com/product-foundations/type-fundamentals/).
- Follow [layout guidelines](https://design.gitlab.com/product-foundations/layout#grid).
- Use existing [icons](https://gitlab-org.gitlab.io/gitlab-svgs/) and [illustrations](https://gitlab-org.gitlab.io/gitlab-svgs/illustrations/)
  or propose new ones according to [iconography](https://design.gitlab.com/product-foundations/iconography/)
  and [illustration](https://design.gitlab.com/product-foundations/illustration/)
  guidelines.
- Optional: Consider dark mode. For more information, see [Change the syntax highlighting theme](../../user/profile/preferences.md#change-the-syntax-highlighting-theme).

### Dark Mode

You're not required to design for dark mode while the feature is an [experiment](../../policy/development_stages_support.md#experiment). The [Design System team](https://about.gitlab.com/direction/foundations/design_system/) plans to improve the dark mode in the future. Until we integrate [Pajamas](https://design.gitlab.com/) components into the product and the underlying design strategy is in place to support dark mode, we cannot guarantee that we won't introduce bugs and debt to this mode. At your discretion, evaluate the need to create dark mode patches.

### States

Check states using your browser's _styles inspector_ to toggle CSS pseudo-classes
like `:hover` and others ([Chrome](https://developer.chrome.com/docs/devtools/css/reference/#pseudo-class),
[Firefox](https://firefox-source-docs.mozilla.org/devtools-user/page_inspector/how_to/examine_and_edit_css/index.html#viewing-common-pseudo-classes)).

- Account for all applicable states (error, rest, loading, focus, hover, selected, disabled).
- Account for states dependent on data size ([empty](https://design.gitlab.com/patterns/empty-states),
  some data, and lots of data).
- Account for states dependent on user role, user preferences, and subscription.
- Consider animations and transitions, and follow their [guidelines](https://design.gitlab.com/brand-design/motion).

### Responsive

Check responsive behavior using your browser's _responsive mode_ ([Chrome](https://developer.chrome.com/docs/devtools/device-mode/#viewport),
[Firefox](https://firefox-source-docs.mozilla.org/devtools-user/responsive_design_mode/index.html)).

- Account for resizing, collapsing, moving, or wrapping of elements across
  all breakpoints (even if larger viewports are prioritized).
- Provide the same information and actions in all breakpoints.

### Accessibility

Check accessibility using your browser's _accessibility inspector_ ([Chrome](https://developer.chrome.com/docs/devtools/accessibility/reference/),
[Firefox](https://firefox-source-docs.mozilla.org/devtools-user/accessibility_inspector/index.html#accessing-the-accessibility-inspector)).

- Conform to level AA of the World Wide Web Consortium (W3C) [Web Content Accessibility Guidelines 2.1](https://www.w3.org/TR/WCAG21/),
  according to our [statement of compliance](https://design.gitlab.com/accessibility/a11y/).
- Follow accessibility [Pajamas' best practices](https://design.gitlab.com/accessibility/best-practices/)
  and read the accessibility developer documentation's [checklist](../fe_guide/accessibility/best_practices.md#quick-checklist).

### Handoff

When the design is ready, _before_ starting its implementation:

- Share design specifications in the related issue, preferably through a [Figma link](https://help.figma.com/hc/en-us/articles/360040531773-Share-files-and-prototypes)
  or [GitLab Designs feature](../../user/project/issues/design_management.md).
  See [when you should use each tool](https://handbook.gitlab.com/handbook/product/ux/product-designer/#deliver).
- Document user flow and states (for example, using [Mermaid flowcharts in Markdown](../../user/markdown.md#mermaid)).
- Document [design tokens](https://design.gitlab.com/product-foundations/design-tokens) (for example using the [design token annotation](https://www.figma.com/file/dWP1ldkBU4jeUqx5rO3jrn/Annotations-and-utilities?type=design&node-id=2002-34) in Figma).
- Document animations and transitions.
- Document responsive behaviors.
- Document non-evident behaviors (for example, field is auto-focused).
- Document accessibility behaviors (for example, using [accessibility annotations in Figma](https://www.figma.com/file/g7QtDbfxF3pCdWiyskIr0X/Accessibility-bluelines)).
- Contribute new icons or illustrations to the [GitLab SVGs](https://gitlab.com/gitlab-org/gitlab-svgs)
  project.

### Follow-ups

At any moment, but usually _during_ or _after_ the design's implementation:

- Contribute [issues to Pajamas](https://design.gitlab.com/get-started/contributing#contribute-an-issue)
  for additions or enhancements to the design system.
- Create issues with the [`~Deferred UX`](../labels/_index.md#technical-debt-and-deferred-ux)
  label for intentional deviations from the agreed-upon UX requirements due to
  time or feasibility challenges, linking back to the corresponding issues or
  merge requests.
- Create issues for [feature additions or enhancements](issue_workflow.md#feature-proposals)
  outside the agreed-upon UX requirements to avoid scope creep.
