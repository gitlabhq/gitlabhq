---
source_checksum: fdddf765995a1dff
distilled_at_sha: 9eb89263152259e883603c908db1e1cea6a1a74e
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Documentation Principles

## Checklist

### Voice and Tone

- Write in US English with US grammar.
- Use active voice instead of passive voice; use passive only when the subject is awkward (e.g., "The report is exported").
- Write from the customer perspective; DO NOT use "allows you to" or "enables you to" — address the user directly with "you".
- DO NOT use marketing phrases like "save you time and money", or words like "easily" or "simply".
- DO NOT write about the document itself (e.g., "This page shows..."); get straight to the point.
- Use contractions for a friendly tone, but DO NOT use contractions to emphasize a negative, with proper nouns as the subject, in reference documentation, or in error messages.
- DO NOT use possessives (`'s`) for product or organization names (e.g., use "the Docker CLI", not "Docker's CLI").

### Language and Grammar

- Spell out acronyms on first use per page; DO NOT spell them out more than once.
- DO NOT make acronyms plural with an apostrophe (use `APIs`, not `API's`).
- Spell out zero through nine; use numerals for 10 and above.
- Use `month day, year` format for dates and `AM`/`PM` for times.
- DO NOT use semicolons (`;`), en dashes (`–`), or em dashes (`—`); use separate sentences or commas instead.
- DO NOT use typographer's ("curly") quotation marks; use straight quotes.
- Use serial (Oxford) commas before the final "and" or "or" in lists of three or more items.
- DO NOT use Latin abbreviations like `e.g.` or `i.e.`.
- DO NOT use `-ing` words, ambiguous pronouns like "it", or phrases that hide the subject like "there is"/"there are".
- Break up noun strings (e.g., use "custom settings for project integrations", not "project integration custom settings").

### Capitalization

- Use sentence case for topic titles and table headers.
- Keep feature names lowercase unless they are listed as exceptions in markdownlint or the word list.
- Capitalize GitLab product tiers (e.g., GitLab Free, GitLab Ultimate), third-party product names, and methodology names.
- DO NOT match capitalization from the Features page or `features.yml` by default.
- Use the same capitalization as displayed in the UI when referring to UI elements; exception: use sentence case for UI text that is all uppercase.

### Fake Data and Tokens

- DO NOT use real usernames, email addresses, or tokens in documentation.
- Use diverse or non-gendered names (e.g., `Sidney Jones`, `Zhang Wei`) and `example.com` email addresses.
- Use `example.com` for generic domains and `gitlab.example.com` for self-managed references.
- Use only the approved fake token values from the token table in the style guide.

### Markdown and Formatting

- DO NOT add an `H1` heading in Markdown; use the `title` metadata attribute instead.
- DO NOT skip heading levels (e.g., `##` directly to `####`).
- DO NOT use heading levels greater than `H5`; move content to a new page instead.
- DO NOT use bold text in topic titles.
- Leave one blank line before and after headings, paragraphs, lists, and code blocks.
- Use dashes (`-`) for unordered lists, not asterisks (`*`).
- Start every ordered list item with `1.`.
- Use two spaces per indentation level for unordered lists; three spaces for ordered lists.
- DO NOT use HTML in Markdown unless no Markdown equivalent exists, the content is reviewed by a technical writer, and the need is urgent.
- Any `<a>` tags created with HTML must use absolute URLs as `href` attributes.
- Use inline links, not reference-style links.
- Split long lines at approximately 100 characters; DO NOT split links across lines.
- Start each new sentence on a new line.
- Use `<!-- comment -->` HTML comments for author notes; DO NOT use comments to hide documentation.

### Text Formatting

- Use **bold** only for UI elements with visible labels and navigation paths; DO NOT use bold for keywords or emphasis.
- Use inline code (backticks) for user input, filenames, configuration parameters, keywords, API/HTTP methods, HTTP status codes, and short error messages.
- Use code blocks for CLI/cURL commands and multi-line inputs/outputs; add a syntax name for highlighting.
- Use `<kbd>` tags for keyboard commands; spell out full key names (except `Alt`); DO NOT use spaces between `<kbd>` tags in combinations.
- DO NOT use italics for emphasis in product documentation.
- Use `<` and `>` to denote placeholder text in code blocks.

### Lists

- Make all list items parallel (same grammatical structure).
- Start all list items with a capital letter.
- DO NOT end list items with a period unless the item is a complete sentence.
- DO NOT use bold formatting to define keywords or concepts in a list; use bold only for UI element labels.
- Use ordered lists for sequential steps; use unordered lists for non-sequential items.
- Add a colon (`:`) after the introductory phrase before a list.
- DO NOT use list items to complete an introductory phrase (e.g., "You can do this by: - Copying..."); rewrite as a full sentence introducing the list.

### Tables

- DO NOT leave table cells empty; use **None** for cells with no meaningful value.
- Make the header row and delimiter row the same length; DO NOT use shortened delimiters like `|-|-|-|`.
- Use sentence case for table headers.
- Place the `Description` column as the right-most column when possible.
- DO NOT realign an entire table when only changing a few rows (to keep diffs readable).
- Use `{{< no >}}` and `{{< yes >}}` shortcodes for feature availability tables; DO NOT use these in API docs or inline text.
- Use `<sup>` tags for table footnotes; place footnotes below the table under `**Footnotes**:` as an ordered list.

### Links

- DO NOT duplicate links on the same page.
- DO NOT use links in headings.
- DO NOT hard-wrap lines within a link.
- Use relative file paths for links within the same repository; use full URLs for links to other repositories or non-doc files.
- Link to a specific commit (permalink) when linking to specific lines of code, not to a branch.
- Use descriptive link text; DO NOT use "here", "this page", or "this documentation" as link text.
- Use the pattern `For more information, see [link text](link.md)` or `To [DO THIS], see [link text](link.md)`.
- DO NOT use "Learn more about...", "To read more...", or append "page" or "documentation" after the link text.
- When linking to an issue, include the issue number in the link text (e.g., `[issue 12345](link)`); DO NOT use the pound sign (`issue #12345`).
- DO NOT link to confidential issues, internal handbook pages, or permission-restricted features directly; put such links in backticks and note the access requirement.
- Limit links to external documentation and handbook pages; weigh customer benefit against maintenance cost.
- DO NOT link to the `/development` directory from any other directory within the GitLab repository.

### Images and Screenshots

- Resize wide or tall screenshots (width ≤ 1000 px, height ≤ 500 px); compress all PNG images to 100 KB or less on disk.
- Use descriptive lowercase filenames; append the GitLab version in the format `_vX_Y` (e.g., `pipelines_v11_1.png`).
- Place images in an `img/` subdirectory alongside the `.md` file.
- Use PNG format; DO NOT use JPEG for screenshots.
- DO NOT delete image files when removing references from English docs (localized docs may still use them).
- DO NOT use animated GIFs; use static screenshots with callouts or link to a short video instead.
- Write alt text that describes the context of the image (≤ 155 characters); DO NOT use phrases like "Image of" or strings of keywords.
- Use an empty alt tag (`alt=""`) for purely decorative images rather than omitting the tag.
- Add callout arrows in `#EE2604` red at 3 pt line width to emphasize areas in screenshots.
- DO NOT link to externally-hosted images; download and store them in the appropriate `img/` directory.

### Diagrams

- Prefer Mermaid for diagrams; use Draw.io for complex layouts where Mermaid produces unclear results.
- Add `accTitle` and `accDescr` accessibility fields immediately after the diagram type declaration in Mermaid.
- DO NOT use color alone to differentiate diagram elements (must work in both light and dark modes).
- DO NOT include links in diagrams (not testable by link checkers).
- Keep diagrams simple; use rectangles for processes, diamonds for decisions, solid lines for direct relationships, dotted lines for indirect relationships.
- Save Draw.io diagrams with the `.drawio.svg` extension and include the diagram definition in the SVG file by selecting **Include a copy of my diagram** on export.

### Alert Boxes and Special Elements

- Use alert boxes sparingly; DO NOT place two alert boxes consecutively.
- Use `> [!note]`, `> [!warning]`, `> [!flag]`, and `> [!disclaimer]` for alert types.
- DO NOT use blockquotes in product documentation; use code blocks, alert boxes, or plain text instead.
- Use the guide shortcode for tutorials only; DO NOT use a guide inside a guide.
- Use collapsible panels only on GitLab Duo pages in the availability details section; DO NOT use them for other content.
- Use cards only on top-level landing pages where cards are the only content.
- DO NOT use Markdown emoji format (`:smile:`); use GitLab SVG icons instead.
- When using SVG icons, place the icon after the label text in parentheses (e.g., `Select **Edit** ({{< icon name="pencil" >}})`).
- Use glossary tooltips only for the first occurrence of a GitLab-specific term or unfamiliar term on a page; DO NOT use them for common terms, every instance of a term, or as a replacement for acronyms. Limit to five to ten tooltips per page.

### Videos and Demos

- DO NOT upload videos to product repositories; link or embed them instead.
- Embed only videos from the official GitLab YouTube channel; link to videos from other sources.
- Include the video publication date as a comment below every video link or embed.
- Include a `<div class="video-fallback">` fallback for embedded videos.
- Use `www.youtube-nocookie.com` in the `src` of embedded video iframes to enable Privacy Enhanced Mode.
- Follow the same guidelines for click-through demo links as for videos.

### Navigation and UI References

- Write navigation steps as location then action (e.g., "From the **Visibility** dropdown list, select **Public**").
- Use **left sidebar** instead of "the Explore menu" or "the Your work sidebar".
- Bold all UI element names; DO NOT bold the `>` separator in navigation paths.
- Place punctuation outside bold tags unless the punctuation is part of the UI element itself.
- Start optional steps with "Optional." followed by a period.
- Start recommended steps with "Recommended." followed by a period.
- Use "Complete the fields" to summarize multiple self-explanatory fields in a single task step rather than documenting each field individually.

### Metadata

- Include `stage`, `group`, `info`, and `title` front matter on every documentation page.
- Use the `title` metadata attribute to set the page H1; DO NOT add a Markdown `# H1` heading.
- Add `gitlab_dedicated: no` (or `yes`) metadata when a page's GitLab Dedicated availability differs from its GitLab Self-Managed availability.
- Add `availability_details: no` metadata on pages that purposely omit availability details.
- Add `ignore_in_report: true` metadata to keep a page out of the global navigation; it excludes the page from the technical writing team's navigation report so the page is not prompted for a `navigation.yaml` entry.
- Add a `description` metadata tag on top-level pages and REST API resource pages; start the description with an active verb for top-level pages.

### Product Availability Details

- Place availability details (`{{< details >}}` shortcode) at the top of the page (after front matter) when they apply to the whole page, or under the applicable section heading when they apply to a specific section.
- Include tier (`Free, Premium, Ultimate` or subset), add-on (for GitLab Duo features only), offering (`GitLab.com`, `GitLab Self-Managed`, `GitLab Dedicated`, `GitLab Dedicated for Government`), and status (`Beta`, `Experiment`, or `Limited availability`) as applicable; DO NOT add a status entry for generally available features.
- DO NOT add availability details to tutorials, tier-comparison pages, `/development` pages, or `/solutions` pages.
- DO NOT repeat tier, offering, or status in a subheading's badge when it matches the parent topic's badge.
- Place history notes (`{{< history >}}` shortcode) after the details block and immediately after the heading; start each entry with `-` and link to the related issue, MR, or epic when possible.
- Remove history items and inline version references that refer to unsupported GitLab versions (current major version and two previous major versions are supported); when a new major version is about to be released, create removal MRs in advance but merge them only during that milestone.
- For tools released on their own schedule (e.g., editor extensions, CLI tools), include both the GitLab version and the tool version in history entries with a link to the tool's release page; nest tool version entries under the related instance history item when both change together, or use `during the GitLab X.Y release` phrasing when the change is tool-only.
- For GitLab Duo features available with self-hosted models, use the `{{< collapsible title="Model information" >}}` shortcode; DO NOT state that a feature is unavailable on self-hosted models unless necessary, and if you must, use "Not available on GitLab Duo with self-hosted models" without a link.
- When documenting LLMs used by a GitLab Duo feature, include a link to the LLM and use separate entries for code generation vs. code completion or Amazon Q when they differ.

### Deprecations and Removals

- When deprecating a feature, add `(deprecated)` after the title, add a `> [!warning]` alert stating when it was deprecated and when it will be removed, and wrap the content in `<!-- remove_date: YYYY-MM-DD -->` HTML comments (set `remove_date` to three months after the planned removal release).
- When removing a feature, change `(deprecated)` to `(removed)` in the title, remove all content except the deprecation/removal statement, set `remove_date` in metadata to three months after the removal release, and set `redirect_to` to a relevant replacement page.
- After removing a page, edit `navigation.yaml` in `docs-gitlab-com` to remove the page's entry from the global navigation, update any links in the [Deprecations and Removals](https://docs.gitlab.com/update/deprecations/) YAML files, and run `bin/rake gitlab:docs:compile_deprecations`.
- DO NOT follow the standard deprecation process for features that are not generally available; delete the content outright instead.
- For features no longer actively developed but not deprecated, add a note under the topic title stating the feature is not under active development but community contributions are welcome.

### Documentation Workflow

- Include documentation in the same MR as the feature code whenever possible; DO NOT merge a feature that exposes UI, API endpoints, or user-facing behaviour without accompanying documentation.
- Ensure AI-generated documentation is reviewed by a Technical Writer and passes a Vale lint check before submission.
- Delete documentation added prematurely rather than hiding it with HTML comments; add a link to the original MR in the removal MR.
- When moving content to a new location and editing it in the same MR, use separate commits (first commit moves only, subsequent commits edit).
- DO NOT promise to deliver features in a future release; instead reference the proposing issue (e.g., "Support for improvements is proposed in [issue 12345](link)").
- Assign the technical writer as a reviewer directly on the MR (not just pinged) before the code maintainer review; documentation reviews must not block merging.
- When a post-merge technical writer review is required, create an issue using the [Doc Review description template](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=Doc%20Review) and link it to the merged MR.
- Name documentation-only branches in `omnibus-gitlab`, `charts/gitlab`, or `gitlab-operator` starting with `docs/`, `docs-`, or ending with `-docs` to trigger shorter pipelines.

### Common Mistakes - Repetition

- Do not restate information already covered earlier in the same page or in a linked topic
- Each section should add new information. Do not summarize what was just explained
- Avoid restating the title or introduction in the first paragraph

### Common Mistakes - Scope

- Do not create a new page for a single concept, term, or procedure step

### Common Mistakes - Accuracy

- Only include information you can ground in the existing codebase, linked documentation, or content already on the page
- Do not speculate or infer how a feature works
- Do not invent command syntax, API parameters, or UI element names

### Screenshot Guidelines

- Resize wide or tall screenshots
- Compress size on disk to 100 KB or less
- Use descriptive lowercase filenames with underscores instead of hyphens
- Filenames should include the major and minor version of GitLab in the format `_v18_6`

### Content Guidelines

- Avoid writing about the document itself; get straight to the point instead of using phrases like "This page shows"
- Do not promise work in future milestones; instead say work is being proposed
- Avoid blockquotes
- When linking to GitLab issues, include the GitLab issue number in the link text
- Start optional steps with "Optional."

### Word List

- Follow the GitLab Documentation recommended word list for consistent terminology

## Authoritative sources

For the full picture, see:

- doc/development/documentation/styleguide/_index.md
- doc/development/documentation/workflow.md
- doc/development/documentation/styleguide/availability_details.md
- doc/development/documentation/styleguide/deprecations_and_removals.md
- doc/development/documentation/metadata.md

