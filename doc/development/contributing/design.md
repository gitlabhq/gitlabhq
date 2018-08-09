## Implement design & UI elements

For guidance on UX implementation at GitLab, please refer to our [Design System](https://design.gitlab.com/).

The UX team uses labels to manage their workflow.

The  ~"UX" label on an issue is a signal to the UX team that it will need UX attention.
To better understand the priority by which UX tackles issues, see the [UX section](https://about.gitlab.com/handbook/engineering/ux) of the handbook.

Once an issue has been worked on and is ready for development, a UXer removes the ~"UX" label and applies the ~"UX ready" label to that issue.

The UX team has a special type label called ~"design artifact". This label indicates that the final output
for an issue is a UX solution/design. The solution will be developed by frontend and/or backend in a subsequent milestone.
Any issue labeled ~"design artifact" should not also be labeled ~"frontend" or ~"backend" since no development is
needed until the solution has been decided.

~"design artifact" issues are like any other issue and should contain a milestone label, ~"Deliverable" or ~"Stretch", when scheduled in the current milestone.

To prevent the misunderstanding that a feature will be be delivered in the
assigned milestone, when only UX design is planned for that milestone, the
Product Manager should create a separate issue for the ~"design artifact",
assign the ~UX, ~"design artifact" and ~"Deliverable" labels, add a milestone
and use a title that makes it clear that the scheduled issue is design only
(e.g. `Design exploration for XYZ`).

When the ~"design artifact" issue has been completed, the UXer removes the ~UX
label, adds the ~"UX ready" label and closes the issue. This indicates the
design artifact is complete. The UXer will also copy the designs to related
issues for implementation in an upcoming milestone.

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
1.  [Shell commands](doc/development/shell_commands.md) created by GitLab
    contributors to enhance security
1.  [Database Migrations](doc/development/migration_style_guide.md)
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
