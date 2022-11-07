---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Concept topic type

A concept introduces a single feature or concept.

A concept should answer the questions:

- What is this?
- Why would I use it?

Think of everything someone might want to know if they've never heard of this concept before.

Don't tell them **how** to do this thing. Tell them **what it is**.

If you start describing another concept, start a new concept and link to it.

Concepts should be in this format:

```markdown
# Title (a noun, like "Widgets")

A paragraph that explains what this thing is.

Another paragraph that explains what this thing is.

Remember, if you start to describe about another concept, stop yourself.
Each concept should be about one concept only.
```

## Concept topic titles

For the title text, use a noun. For example, `Widgets` or `GDK dependency management`.

If a noun is ambiguous, you can add a gerund. For example, `Documenting versions` instead of `Versions`.

Avoid these topic titles:

- `Overview` or `Introduction`. Instead, use a more specific
  noun or phrase that someone would search for.
- `Use cases`. Instead, incorporate the information as part of the concept.
- `How it works`. Instead, use a noun followed by `workflow`. For example, `Merge request workflow`.
