---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Glossary topic type
---

A glossary provides a list of unfamiliar terms and their definitions to help users understand a specific
GitLab feature.

Each glossary item provides a single term and its associated definition. The definition should answer the questions:

- **What** is this?
- **Why** would you use it?

For glossary terms:

- Do not use jargon.
- Do not use internal terminology or acronyms.
- Ensure the correct usage is defined in the [word list](../styleguide/word_list.md).

## Alternatives to glossaries

Glossaries should provide short, concise term-definition pairs.

- If a definition requires more than a brief explanation, use a concept topic instead.
- If you find yourself explaining how to use the feature, use a task topic instead.

## Glossary example

Glossary topics should be in this format. Use an unordered list primarily. You can use a table if you need to apply
additional categorization.

Try to include glossary topics on pages that explain the feature, rather than as a standalone page.

```markdown
## FeatureName glossary

This glossary provides definitions for terms related to FeatureName.

- **Term A**: Term A does this thing.
- **Term B**: Term B does this thing.
- **Term C**: Term C does this thing.
```

If you use the table format:

```markdown
## FeatureName glossary

This glossary provides definitions for terms related to FeatureName.

| Term   | Definition              | Additional category |
|--------|-------------------------|---------------------|
| Term A | Term A does this thing. |                     |
| Term B | Term B does this thing. |                     |
| Term C | Term C does this thing. |                     |
```

## Glossary topic titles

Use `FeatureName glossary`.

Don't use alternatives to `glossary`. For example:

- `Terminology`
- `Glossary of terms`
- `Glossary of common terms`
- `Definitions`
