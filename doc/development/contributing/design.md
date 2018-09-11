<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Implement design & UI elements](#implement-design--ui-elements)
- [Style guides](#style-guides)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Implement design & UI elements

For guidance on UX implementation at GitLab, please refer to our [Design System](https://design.gitlab.com/).

The UX team uses labels to manage their workflow.

The  ~"UX" label on an issue is a signal to the UX team that it will need UX attention.
To better understand the priority by which UX tackles issues, see the [UX section](https://about.gitlab.com/handbook/engineering/ux) of the handbook.

Once an issue has been worked on and is ready for development, a UXer removes the ~"UX" label and applies the ~"UX ready" label to that issue.

There is a special type label called ~"product discovery". It represents a discovery issue intended for UX, PM, FE, and BE to discuss the problem and potential solutions. The final output for this issue could be a doc of requirements, a design artifact, or even a prototype. The solution will be developed in a subsequent milestone.

~"product discovery" issues are like any other issue and should contain a milestone label, ~"Deliverable" or ~"Stretch", when scheduled in the current milestone.

The initial issue should be about the problem we are solving. If a separate [product discovery issue](#product-discovery-issues) is needed for additional research and design work, it will be created by a PM or UX person. Assign the ~UX, ~"product discovery" and ~"Deliverable" labels, add a milestone and use a title that makes it clear that the scheduled issue is product discovery
(e.g. `Product discovery for XYZ`).

In order to complete a product discovery issue in a release, you must complete the following:

1. UXer removes the ~UX label, adds the ~"UX ready" label.
1. Modify the issue description in the product discovery issue to contain the final design. If it makes sense, the original information indicating the need for the design can be moved to a lower "Original Information" section.
1. Copy the design to the description of the delivery issue for which the product discovery issue was created. Do not simply refer to the product discovery issue as a separate source of truth.
1. In some cases, a product discovery issue also identifies future enhancements that will not go into the issue that originated the product discovery issue. For these items, create new issues containing the designs to ensure they are not lost. Put the issues in the backlog if they are agreed upon as good ideas. Otherwise leave them for triage.

## Style guides

1.  [Ruby](https://github.com/bbatsov/ruby-style-guide).
    Important sections include [Source Code Layout][rss-source] and
    [Naming][rss-naming]. Use:
    - multi-line method chaining style **Option A**: dot `.` on the second line
    - string literal quoting style **Option A**: single quoted by default
1.  [Rails](https://github.com/bbatsov/rails-style-guide)
1.  [Newlines styleguide][newlines-styleguide]
1.  [Testing][testing]
1.  [JavaScript styleguide][js-styleguide]
1.  [SCSS styleguide][scss-styleguide]
1.  [Shell commands](../shell_commands.md) created by GitLab
    contributors to enhance security
1.  [Database Migrations](../migration_style_guide.md)
1.  [Markdown](http://www.cirosantilli.com/markdown-styleguide)
1.  [Documentation styleguide](https://docs.gitlab.com/ee/development/documentation/styleguide.html)
1.  Interface text should be written subjectively instead of objectively. It
    should be the GitLab core team addressing a person. It should be written in
    present time and never use past tense (has been/was). For example instead
    of _prohibited this user from being saved due to the following errors:_ the
    text should be _sorry, we could not create your account because:_
1.  Code should be written in [US English][us-english]

This is also the style used by linting tools such as
[RuboCop](https://github.com/bbatsov/rubocop),
[PullReview](https://www.pullreview.com/) and [Hound CI](https://houndci.com).

---

[Return to Contributing documentation](index.md)
