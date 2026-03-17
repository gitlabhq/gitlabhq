---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
description: Writing styles, markup, formatting, and other standards for GitLab Documentation.
title: Documentation AGENTS.md
---

The [`AGENTS.md`](../../AGENTS.md) file provides documentation instructions for GitLab Duo.
When an agent writes documentation in the `gitlab/doc` directory, it
reads `AGENTS.md` automatically and applies the instructions to its output.

Before you submit AI-generated content for review, ensure the following:

- Content is accurate.
- Common problems wth AI-generated content, like hallucinations and repetitive content, are addressed.

## Use AGENTS.md

`AGENTS.md` is applied automatically at the start of each new GitLab Duo Chat
conversation. You do not need to reference it in your prompt. To get the best
results:

- Start a new chat conversation before beginning a documentation task.
- Make changes locally only. Do not commit or push AI-generated content before
  you have reviewed and iterated on the output.

## Location

The `AGENTS.md` file is located in `gitlab/doc/AGENTS.md`.
Because of the location, the instructions apply to documentation only. The instructions are not
applied when contributors work on unrelated parts of the codebase.

## Review AI-generated content

Before you request a review, check for the following known issues
with AI-generated content:

- Repetition: Content that restates what has already be said on the page
  or in a linked topic.
- Vague or unverifiable claims: Descriptions of how a feature works that
  aren't grounded in the codebase or existing documentation.
- Incorrect scope: A new page has been created for a concept or procedure when a suitable
  page already exists. If you are unsure, Technical Writers can help identify a location
  in the documentation.
- Style guide adherence: Terms, grammar, and formatting that don't align with [the style guide](_index.md).

## Update AGENTS.md

If you notice a recurring pattern in AI-generated content, open an MR to add or refine an
instruction.

When you update the file, follow these principles:

- Keep instructions specific and actionable. Avoid vague guidance like `Write
  concisely`.
- Use examples when an instruction requires judgment. Instead of `Avoid marketing language`,
  provide an example: `Avoid marketing language. For example, do not use "powerful" or "seamless"`.
- Test your changes. Start a new chat conversation and ensure the instruction is
  applied.
- If you update `AGENTS.md`, conversations must be restarted for changes to take
  effect. Existing conversations do not pick up changes automatically.
