<!-- markdownlint-disable -->
<!-- vale off -->

## Output requirements

- Write the complete documentation.
- Adhere to the following style guidelines.

## Voice and tone

- Write for the task the user is trying to complete, not to explain the feature itself. For example, use "Use variables to store API keys securely"
  instead of "This feature is designed to allow you to store API keys securely"
- Do not use marketing language. For example, do not use "easily", "powerfully", or "simply"

## Writing style

- Use present tense: Use "The system manages" not "The system will manage"
- Use active voice: Use "The developer writes code" not "Code is written by the developer"
- Use U.S. spelling.
- Be direct: Use "Use this feature to..." not "This allows you to..." or "This enables you to..."
- Be concise: Remove unnecessary words.
- Split lines at ~100 characters. Do not split links.
- Sentences should be fewer than 20 words when possible. Break complex ideas into multiple sentences.
- Aim for eighth-grade reading level.

## GitLab product names

- Do not use possessive: "GitLab policies" not "GitLab's policies"
- "GitLab Duo" not "Duo"
- "GitLab Duo Agent Platform" not "DAP" or "Duo Agent Platform"
- Offerings:
  - "GitLab.com" not "GitLab SaaS"
  - "GitLab Self-Managed" not "Self-managed"
  - "GitLab Dedicated" not "Dedicated"
  - "GitLab Dedicated for Government" not "Dedicated for Government"

## Capitalization

- Topic titles: Use sentence case.
- UI text: Match the exact capitalization in the interface.
- Feature names: Use lowercase.

## Text formatting

- Bold (**text**) for UI elements only (buttons, menus, pages, settings).
- Inline code (`text`) for commands, filenames, parameters, and keywords.
- Keyboard entries use the format: <kbd>Control</kbd>+<kbd>C</kbd>.
- Code blocks for CLI commands and multi-line code. Use the appropriate language identifier.
  ```shell
  git commit -m "message"
  ```

## Lists

- "-" for unordered lists, and "1." for all items in an ordered list.
- Use an unordered list item for tasks with only one step.
- Make items parallel.
- Start each line with a capital letter and end with a period.
- Use a blank line before and after each list.

## Links

- Use relative paths for links in the same repository. For example `[text](path/to/file.md)`.
- Use descriptive link text, not "here"
- Include the number in issue links. For example, "For more information, see issue 12345."
- Follow the style, "For more information, see `[link text](<link>)`."
- Avoid multiple links in the same paragraph.

## Headings

- Use ## through #### (H2-H4). Never skip levels.
- Do not use H1. The title in front matter is the H1.
- Use sentence case. Do not use bold text.
- Avoid generic titles. Instead:
  - For concept and reference sections, use descriptive nouns that explain what the concept or reference is:
    "Access controls," "Group hierarchy," "Protection levels," "Understand protection levels"
  - For procedure sections, use action verbs that describe what users will accomplish:
    "Create a group," "Remove a member from a group," "View flows in a project"
  - Do not use vague titles like "Overview," "Introduction," "Setup," "Configuration," or "How to use"

## Punctuation

- Use the Oxford comma (a comma between all list items).
- Avoid semicolons, em dashes, and curly quotes.
- For placeholder text or variables, use <your_value>.

## Navigation steps

- Location first, then action: "On the left sidebar, select **Settings**."
- Be brief: "Select **Save**." not "Select **Save** for changes to take effect."
- Start optional steps with "Optional."
- For the UI, use: top bar, left sidebar, right sidebar, and details panel.

## Tables

- The Description column should be on the right.
- Use sentence case for headers.
- Use these shortcodes for feature tables: {{< yes >}} and {{< no >}}.

## Alerts

- Use alerts, like note and warning, sparingly.
- Use this syntax:
  ```markdown
  > [!note]
  > This is something to note.
  ```
- Use alerts for:
  - **Warnings**: Destructive actions with serious consequences, security implications, or important constraints that could cause failures.
  - **Notes**: Supplementary information that clarifies context, exceptions, or special cases.

## Common mistakes to avoid

- Avoid "there is" or "there are." Use "The pipeline has errors" not "There are errors in the pipeline"
- Use specific nouns instead of "it."
- Use active verbs instead of "-ing" words.
- Avoid Latin abbreviations. Use "for example" instead of "e.g." Use "through" or "by using" instead of "via."
- Avoid filler phrases like "this powerful feature", "easily", or "simply." Be specific about what something does and how.

### Repetition

- Do not restate information already covered earlier in the same page or in a linked topic.
- Each section should add new information. Do not summarize what was just explained.
- Avoid restating the title or introduction in the first paragraph.

### Scope

- Do not create a new page for a single concept, term, or procedure step.

### Accuracy

- Only include information you can ground in the existing codebase, linked documentation, or content already on the page.
- Do not speculate or infer how a feature works.
- Do not invent command syntax, API parameters, or UI element names.
