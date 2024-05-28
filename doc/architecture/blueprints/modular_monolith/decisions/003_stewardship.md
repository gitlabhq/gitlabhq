---
creation-date: "2024-05-08"
authors: [ "@fabiopitino" ]
---

# Modular Monolith ADR 003: Module stewardship

## Context

How do we assign stewardship to domain and platform modules? We have a large amount of shared code
that does not have explicit stewards who can provide a vision and direction on that part of code.

## Decision

We use the term **stewards** instead of **owners** to be more in line with GitLab principle of
**everyone can contribute**. Stewards are care takers of the code. They know how a specific
functionality is designed and why. They know the architectural characteristics and constraints.
However, they welcome changes and guide contributors towards success.

A module, whether is from a domain bounded context or platform module, must have at least 1 group of stewards.
This group can be a team name (or GitLab group handle). Optionally, the list of stewards can include
single IC entries.

When we will use a Packwerk package to extract a module we will be able to indicate stewardship directly
in the `package.yml`:

```yaml
metadata:
  stewards:
    - group::pipeline execution # team name
    - group::pipeline authoring # team name
    - @grzesiek  # IC
    - @ayufan    # IC
```

For platform modules (e.g. `Gitlab::Redis`) we might not have a whole team dedicated as stewards since
all platform code is classified as "shared". However, team members can add themselves as experts of a
particular functionality.

## Consequences

Stewardship defined in code can be very powerful:

- Sections of CODEOWNERS could be automatically generated from packages' metadata.
- Review Roulette or Suggested Reviews features can use this list as first preference.
- Engineers can easily identify stewards and have design conversations early.
- Gems living in the monolith (`gems/`), which should be wrapped into a Packwerk package,
  can benefit of having explicit stewards.

## Alternatives

In the initial phase of modularization, before adopting Packwerk, we don't have an explicit concept
of ownership. We are initially relying on each team to know what bounded contexts they are responsible
for. For the "shared code" in the platform modules we initially expect maintainers to fill the role of
stewards.

- Pros: we give trainee maintainer a clear development path and goals. Today it feels unclear what they must
  learn in order to become successful maintainers.
- Cons: The amount of "shared" code is very large and still hard to understand who knows best about
  a particular functionality. Even extracting code into gems doesn't solve the lack of explicit ownership.
