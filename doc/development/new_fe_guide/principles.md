# Principles

These principles will ensure that your frontend contribution starts off in the right direction.

## Discuss architecture before implementation

Discuss your architecture design in an issue before writing code. This helps decrease the review time and also provides good practice for writing and thinking about system design.

## Be consistent

There are multiple ways of writing code to accomplish the same results. We should be as consistent as possible in how we write code across our codebases. This will make it more easier us to maintain our code across GitLab.

## Enhance progressively

Whenever you see with existing code that does not follow our current style guide, update it proactively. Refrain from changing everything but each merge request should progressively enhance our codebase and reduce technical debt.

## When to use Vue

- Use Vue for feature that make use of heavy DOM manipulation
- Use Vue for reusable components

## When to use jQuery

- Use jQuery to interact with Bootstrap JavaScript components
- Avoid jQuery when a better alternative exists. We are slowly moving away from it [#43559][jquery-future]

## Mixing Vue and jQuery

- Mixing Vue and jQuery is not recommended.
- If you need to use a specific jQuery plugin in Vue, [create a wrapper around it][select2].
- It is acceptable for Vue to listen to existing jQuery events using jQuery event listeners.
- It is not recommended to add new jQuery events for Vue to interact with jQuery.

[jquery-future]: https://gitlab.com/gitlab-org/gitlab-ce/issues/43559
[select2]: https://vuejs.org/v2/examples/select2.html
