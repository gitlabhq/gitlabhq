---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting topic type

Troubleshooting topics should be the final topics on a page.

If a page has more than five troubleshooting topics, put the content on a separate page that has troubleshooting information exclusively. Name the page `Troubleshooting <feature>`
and in the left nav, use the word `Troubleshooting` only.

Troubleshooting can be one of three types.

## An introductory topic

This topic introduces the troubleshooting section of a page.
For example:

```markdown
## Troubleshooting

When working with <x feature>, you might encounter the following issues.
```

## Troubleshooting task

The title should be similar to a [standard task](task.md).
For example, "Run debug tools" or "Verify syntax."

## Troubleshooting reference

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
