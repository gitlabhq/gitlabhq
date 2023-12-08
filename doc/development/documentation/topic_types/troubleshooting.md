---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Troubleshooting topic type

Troubleshooting topics should be the final topics on a page.

If a page has five or more troubleshooting topics, put those topics on a separate page.

- Name the page `Troubleshooting <feature>`.
- In the left nav, use the word `Troubleshooting` only.

## What type of troubleshooting information to include

Troubleshooting information includes:

- Problem-solving information that might be considered risky.
- Information about rare cases. All troubleshooting information
  is included, no matter how unlikely a user is to encounter a situation.

This kind of content can be helpful to others, and the benefits outweigh the risks.
If you think you have an exception to this rule, contact the Technical Writing team.

GitLab Support maintains their own
[troubleshooting content](../../../administration/troubleshooting/index.md).

## Format

Troubleshooting can be one of three types: introductory, task, or reference.

### An introductory topic

This topic introduces the troubleshooting section of a page.
For example:

```markdown
## Troubleshooting

When working with <x feature>, you might encounter the following issues.
```

### Troubleshooting task

The title should be similar to a [standard task](task.md).
For example, "Run debug tools" or "Verify syntax."

### Troubleshooting reference

This topic includes the error message. For example:

```markdown
### The error message or a description of it

You might get an error that states <error message>.

This issue occurs when...

The workaround is...
```

If multiple causes or workarounds exist, consider putting them into a table format.
If you use the exact error message, surround it in backticks so it's styled as code.

## Troubleshooting topic titles

For the title of a **Troubleshooting reference** topic:

- Consider including at least a partial error message.
- Use fewer than 70 characters.
- Do not use links in the title.

If you do not put the full error in the title, include it in the body text.

## Rails console write functions

If the troubleshooting suggestion includes a function that changes data on the GitLab instance,
add the following warning:

```markdown
WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.
```
