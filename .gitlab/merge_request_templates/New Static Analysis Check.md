<!--
When creating a new cop that could be applied to multiple applications,
we encourage you to add it to https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles gem.
-->

## Description of the proposal

<!--
Please describe the proposal and add a link to the source (for example, http://www.betterspecs.org/).
-->

### Check-list

- [ ] Make sure this MR enables a static analysis check rule for new usage but
  ignores current offenses.
- [ ] Mention this proposal in the relevant Slack channels (e.g. `#development`, `#backend`, `#frontend`).
- [ ] If there is a choice to make between two potential styles, set up an emoji vote in the MR:
  - CHOICE_A: :a:
  - CHOICE_B: :b:
  - Vote for both choices, so they are visible to others.
- [ ] The MR doesn't have significant objections, and is getting a majority of :+1: vs :-1: (remember that [we don't need to reach a consensus](https://handbook.gitlab.com/handbook/values/#collaboration-is-not-consensus)).
- [ ] (If applicable) One style is getting a majority of vote (compared to the other choice).
- [ ] (If applicable) Update the MR with the chosen style.
- [ ] Create a follow-up issue to fix the current offenses as a separate iteration: ISSUE_LINK
- [ ] Follow the [review process](https://docs.gitlab.com/ee/development/code_review.html) as usual.
- [ ] Once approved and merged by a maintainer, mention it again:
  - [ ] In the relevant Slack channels (e.g. `#development`, `#backend`, `#frontend`).
  - [ ] (Optional depending on the impact of the change) In the Engineering Week in Review.

/label ~"Engineering Productivity" ~"development guidelines" ~"static code analysis"

/cc @gitlab-org/maintainers/rails-backend
