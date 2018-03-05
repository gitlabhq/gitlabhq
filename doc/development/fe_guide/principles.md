# Principles

These principles will ensure that your frontend contribution starts off in the right direction.

## Discuss architecture before implementation

Discuss your architecture design in an issue before writing code. This helps decrease the review time and also provides good practice for writing and thinking about system design.

## When to use Vue

- Use Vue for features that perform a lot of read and write operations to the DOM because it is more performant (E.g. features that require real time updates)
- Use Vue for components that will be reused in other parts of GitLab

## When to use jQuery

- Use jQuery when interactiong with Bootstrap JavaScript components
- Consider not using jQuery if an alternative exists because we are slowly moving away from it [#43559](https://gitlab.com/gitlab-org/gitlab-ce/issues/43559)
