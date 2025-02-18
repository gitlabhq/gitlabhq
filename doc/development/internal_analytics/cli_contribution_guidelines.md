---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contributing to the Internal Events CLI
---

## Priorities of the CLI

1. Feature parity with the instrumentation capabilities as the CLI is the intended entrypoint for all instrumentation tasks
1. Performance and manual testing are top priorities, as the CLI is primarily responsible for giving users a clean & clear UX
1. If a user opts not to use the CLI, danger/specs/pipelines still ensure definition validity/data integrity/functionality/etc

## UX Style Guide & Principles

### When the generator should be used

The internal events generator _should_:

- be a one-stop-shop for any engineering tasks related to instrumenting metrics

The internal events generator _should not_:

- be required; users should be able to perform the same tasks manually

### What we expect of users

The internal events generator _should_:

- protect users from making mistakes
- communicate which tasks still need to be completed to achieve their goal at any given time
- communicate the consequences of selecting a particular option or inputting any text based on only the information they see on the screen

The internal events generator _should not_:

- require users to know anything about instrumentation before running the generator
- require the user to switch screens if certain context is needed in order to complete a given task
- block users from proceeding without offering an alternate path forward

### What we expect of the development environment

The internal events generator _should_:

- be faster than manually performing the same tasks
- leave the user's environment in a clean & valid state if force-exited

The internal events generator _should not_:

- break when invalid user-generated content exists
- require Rails to be running
- require a functioning GDK for usage

### Setting expectations with the user

The internal events generator _should_:

- show a progress bar and detail the required steps at the top of each screen
- have outcome-based entrypoints defining each flow
- use a casual and enthusiastic tone

### Communicating information to the user

The internal events generator _should_:

- provide textual labels and explanations for everything
- always print the `InternalEventsCli::Text::FEEDBACK_NOTICE` when a user exits the CLI
- use examples to illustrate outcomes

The internal events generator _should not_:

- use color & formatting as the exclusive mechanism to communicate information or context

### Collecting information from the user

The internal events generator _should_:

- prefer using select menus to plain text inputs
- auto-fill with defaults where possible or use previous selections to infer information
- select the most common use-case as the first/easiest/default option
- always allow any valid option; the CLI should never assume the most common use-case is always used

The internal events generator _should not_:

- require the user to re-enter the same information multiple times
- have interactions extending "past the fold" of the screen when using the CLI full-screen (where possible)

## Design Tips

- Refer to `scripts/internal_events/cli/helpers/formatting.rb` for formatting different types of information and inputs.
- Adding or removing content can change how well a flow works. Always consider the wider context & don't be afraid to make other modifications to improve UX.
- Instead of a multi-select menu with dependencies & validations, consider using a single-select menu listing each allowable combination. This may not always work well, but it is a quicker interaction and makes the outcome of the selection clearer to the user.
- When adding to an existing flow, match the formatting and structure of the existing screens as closely as possible. Think about the function each piece of text is serving, and either a) group related text by its function, or b) group related text by subject and use the same functional order for each subject.

## Development Practices

- Feature documentation: Co-release documentation updates with CLI updates
  - If the CLI is our recommended entrypoint for all instrumentation, it must always be feature-complete. It should
    not lag behind the documentation or the features we announce to other teams.
- CLI documentation: Rely on inline or co-located documentation of CLI code as much as possible
  - The more likely we are to stumble upon context/explanation while working on the CLI, the more likely we are to a) reduce the likelihood of unused/duplicate code and b) increase code navigability and speed of re-familiarization.
- Testing: Approach tests the same as you would for a frontend application
  - Automated tests should be primarily UX-oriented E2E tests, with supplementary edge case testing and unit tests on an as-needed basis.
  - Apply unit tests in places where they are absolutely necessary to guard against regressions.
- Verification: Always run the CLI directly when adding feature support
  - We don't want to rely only on automated tests. If our goal is great user-experience, then we as users are a critical tool in making sure everything we merge serves that goal. If it's cumbersome & annoying to manually test, then it's probably also cumbersome and annoying to use.

## FAQ

**Q:** Why don't `InternalEventsCli::Event` & `InternalEventsCli::Metric` use `Gitlab::Tracking::EventDefinition` & `Gitlab::Usage::MetricDefinition` respectively?

**A:** Using the `EventDefinition` & `MetricDefinition` classes would require GDK to be running and the rails app to be loaded. The performance of the CLI is critical to its usability, so separate classes are worth the value snappy startup times provide. Ideally, this will be refactored in time such that the same classes can be used for both the CLI & the rails app. For now, the rails app and the CLI share the `json-schemas` for the definitions as a single source of truth.
