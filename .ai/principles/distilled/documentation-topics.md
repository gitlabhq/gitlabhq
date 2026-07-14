---
source_checksum: 7156e605ce1f9813
distilled_at_sha: 45de85c05dd95accf55f90cd5dd29cc3b74dfd74
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Documentation Topics Principles

## Checklist

### Topic Types (CTRT)

- Ensure every topic on a page is one of the four primary types: Concept, Task, Reference, or Troubleshooting.
- Start every page (even short ones) with a concept topic, followed by a task or reference topic.
- Use Tutorial, Get started, Top-level, Prompt example, Related topics, or Glossary only for their designated page/topic roles.

### Pages and Topics to Avoid

- DO NOT create pages that are exclusively links to other pages; Exception: top-level pages that aid navigation.
- DO NOT write topics with only one or two sentences — incorporate the information into another topic, or use a Related topics link if the sentence links to another page.

### Topic Title Guidelines

- Keep topic titles under 70 characters when possible (enforced by the markdownlint `line-length` (MD013) rule).
- Use articles and prepositions in topic titles.
- DO NOT repeat text from earlier topic titles on the same page (e.g., on a merge requests page, use `Troubleshooting`, not `Troubleshooting merge requests`).
- DO NOT use hyphens to separate information in topic titles; use a space or restructure instead (e.g., use `Internal analytics architecture`, not `Internal analytics - Architecture`).

### Concept Topics

- Use a noun (not a verb or gerund) for concept topic titles (e.g., `Widgets`, `Object migration`).
- DO NOT use `Overview`, `Introduction`, `Use cases`, or `How it works` as concept topic titles; use a specific noun or `<noun> workflow` instead.
- DO NOT describe how to use a feature in a concept topic; reserve that for task topics.
- DO NOT include links to related tasks in a concept topic; the navigation provides those links.
- Start a new concept topic (and link to it) when a second concept begins to emerge within the current one.

### Task Topics

- Use `active verb + noun` structure for task topic titles (e.g., `Create an issue`).
- Start the task introduction with `active verb + noun` and provide context (e.g., `Create an issue when you want to track bugs or future work`).
- Start the task steps section with a succinct action followed by a colon (e.g., `To create an issue:`).
- List all applicable roles (other than Guest) in the prerequisites; use `Administrator access.` when only admins can perform the task.
- Always write `Prerequisites` as plural, even when the list has only one item.
- DO NOT list subscriptions or add-ons in prerequisites; include those only in product availability details.
- Write prerequisite statements as a list of nouns (implying `You must have:`) or a list of verbs (implying `You must:`); DO NOT use phrases like `Ensure that` or `You must have`.
- When a task has only one step, format that step as an unordered list item (not a numbered list).
- Document only the primary UI method when multiple ways exist to perform a task; Exception: when multiple methods must be documented, nest sub-topics one level below the task title, list them in descending likelihood order, and use `infinitive + noun` titles.
- DO NOT use a separate heading for a one-sentence API link in a task topic; if the API must be mentioned, add a single trailing sentence: `To <verb> a <noun>, you can also [use the API](link.md).`
- DO NOT include API examples in the **Use GitLab** documentation; put them in the API documentation (GraphQL examples go on their own page).

### Reference Topics

- Use a noun for reference topic titles (e.g., `Pipeline settings`, `Administrator options`).
- Format reference content as an easily-scannable table or list.
- DO NOT use `Important notes` or `Limitations` as reference topic titles; move that content near where it belongs, or use `Known issues` if necessary.

### Troubleshooting Topics

- Place troubleshooting topics as the final topics on a page.
- Create a separate troubleshooting page when a page has five or more troubleshooting topics; name it `Troubleshooting <feature>`, name the file `<feature>_troubleshooting.md`, use `Troubleshooting` only in the left nav, and nest it under the feature in the navigation file.
- Use **workaround** for temporary solutions and **resolution**/**resolve** for permanent solutions in troubleshooting reference topics.
- For troubleshooting reference topic titles: include at least a partial error message; prefix with `Error:` or `Warning:`; use an ellipsis (`...`) to shorten long messages; DO NOT use links in the title; keep titles under 70 characters (do not disable the `line-length` markdownlint rule).
- When a troubleshooting title is shorter than the full message, include the full message in the body text.
- Add the following warning block when a troubleshooting suggestion includes a Rails console function that changes data:
  ```markdown
  > [!warning]
  > Commands that change data can cause damage if not run correctly or under the right conditions.
  > Always run commands in a test environment first and have a backup instance ready to restore.
  ```

### Tutorial Pages

- Start tutorial page titles with `Tutorial:` followed by an active verb (e.g., `Tutorial: Create a website`).
- Use the full page title (with `Tutorial:`) in the left nav, in quotes; DO NOT abbreviate it.
- DO NOT use `Tutorial` in the title on the **Learn GitLab with tutorials** landing page.
- Save tutorial files either in the product documentation directory or as `_index.md` in a subfolder under `doc/tutorials/`; add a link to the tutorial on one of the landing pages.
- Ensure tutorials provide a working (or closely replicable) example and combine multiple tasks toward a specific goal; DO NOT use a tutorial to introduce new features.
- Use a friendlier, more conversational tone in tutorials than in other topic types; add encouraging phrases and use future tense when introducing steps (disable the `gitlab_base.FutureTense` Vale rule to avoid false positives).
- Set `stage: Tutorials` and `group: Tutorials` metadata when the tutorial content does not align with a single group.
- For tutorials with complex steps, use the `guide` shortcode to create a stylized ordered list within each section.

### Get Started Pages

- Use `Get started with <topic_name>` for the page title and `Getting started` for the left nav entry.
- Store all Get started files in `doc/user/get_started/`; DO NOT create a subfolder for each file.
- Use Get started pages only at the highest level of the left navigation.
- Include a workflow diagram and group features by workflow step; save links for the `For more information` area at the end of each step, not inline in body content.

### Top-Level Pages

- Use an active verb phrase for top-level page titles (e.g., `Manage your infrastructure`).
- List only the pages one level below the top-level page, using the `cards` shortcode.
- Set the `description` metadata to list 3–4 features linked from the page (this text appears on the GitLab documentation home page).

### Glossary Topics

- Use `FeatureName glossary` as the glossary topic title; DO NOT use alternatives such as `Terminology`, `Glossary of terms`, or `Definitions`.
- Format glossary content primarily as a description list; use a table only when additional categorization is needed.
- Include glossary topics on the feature's own page rather than as a standalone page.
- Use a concept topic instead of a glossary when a definition requires more than a brief explanation; use a task topic when the content describes how to use the feature.
- DO NOT use jargon, internal terminology, or acronyms in glossary terms; ensure correct usage is defined in the word list.

### Prompt Example Pages

- Use `active verb + noun` structure for prompt example page titles (e.g., `Refactor legacy code`).
- DO NOT use `How to [do something]`, `Using GitLab Duo for [task]`, `Tips and tricks`, or generic titles as prompt example titles.
- Use `[descriptive_name]` format for all prompt placeholders (e.g., `[ClassName]`, `[file_path]`); DO NOT use vague placeholders like `[name]` or `[thing]`.
- Assign difficulty levels using the defined criteria: Beginner (copy-paste, minimal customization), Intermediate (template adaptation required), Advanced (multi-step iteration and custom approaches).
- Make expected outcomes specific and measurable (e.g., `Detailed analysis identifying 3-5 specific improvement areas with code examples`), not vague (e.g., `Analysis of the code`).
- Include 3–5 specific, measurable verification checks in the `Verify` section.

### Related Topics

- Place the **Related topics** section above the Troubleshooting section.
- Use topic titles (not complete sentences) as link text in Related topics; DO NOT end them with periods.

## Documentation Structure

Refer to the authoritative sources for examples of how to structure documentation:

- doc/development/documentation/topic_types/concept.md
- doc/development/documentation/topic_types/task.md
- doc/development/documentation/topic_types/reference.md
- doc/development/documentation/topic_types/troubleshooting.md

## Authoritative sources

For the full picture, see:

- doc/development/documentation/topic_types/_index.md
- doc/development/documentation/topic_types/concept.md
- doc/development/documentation/topic_types/task.md
- doc/development/documentation/topic_types/reference.md
- doc/development/documentation/topic_types/troubleshooting.md
- doc/development/documentation/topic_types/tutorial.md
- doc/development/documentation/topic_types/get_started.md
- doc/development/documentation/topic_types/glossary.md
- doc/development/documentation/topic_types/top_level_page.md

