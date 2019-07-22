---
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
---

# Documentation Style Guide

This document defines the standards for GitLab's documentation content and files.

For broader information about the documentation, see the [Documentation guidelines](index.md).

For programmatic help adhering to the guidelines, see [linting](index.md#linting).

See the GitLab handbook for further [writing style guidelines](https://about.gitlab.com/handbook/communication/#writing-style-guidelines)
that apply to all GitLab content, not just documentation.

## Documentation is the single source of truth (SSOT)

### Why a single source of truth

The documentation is the SSOT for all information related to the implementation, usage, and troubleshooting of GitLab products and features. It evolves continually, in keeping with new products and features, and with improvements for clarity, accuracy, and completeness.

This policy prevents information silos, ensuring that it remains easy to find information about GitLab products.

It also informs decisions about the kinds of content we include in our documentation.

The documentation is a continually evolving SSOT for all information related to the implementation, usage, and troubleshooting of GitLab products and features.

### All information

Include problem-solving actions that may address rare cases or be considered 'risky', so long as proper context is provided in the form of fully detailed warnings and caveats. This kind of content should be included as it could be helpful to others and, when properly explained, its benefits outweigh the risks. If you think you have found an exception to this rule, contact the Technical Writing team.

We will add all troubleshooting information to the documentation, no matter how unlikely a user is to encounter a situation.
For the Troubleshooting sections, people in GitLab Support can merge additions themselves.

### All media types

Include any media types/sources if the content is relevant to readers. You can freely include or link presentations, diagrams, videos, etc.; no matter who it was originally composed for, if it is helpful to any of our audiences, we can include it.

   - If you use an image that has a separate source file (for example, a vector or diagram format), link the image to the source file so that it may be reused or updated by anyone.
   - Do not copy and paste content from other sources unless it is a limited quotation with the source cited. Typically it is better to either rephrase relevant information in your own words or link out to the other source.

### No special types

In the software industry, it is a best practice to organize documentatioin in different types. For example, [Divio recommends](https://www.divio.com/blog/documentation/):

1. Tutorials
1. How-to guides
1. Explanation
1. Reference (for example, a glossary)

At GitLab, we have so many product changes in our monthly releases that we can't afford to continually update multiple types of information.
If we have multiple types, the information will become outdated. Therefore, we have a [single template](structure.md) for documentation.

We currently do not distinguish specific document types, although we are open to reconsidering this policy
once the documentation has reached a future stage of maturity and quality. If you are reading this, then despite our
continual improvement efforts, that point hasn't been reached.

### Link instead of summarize

There is a temptation to summarize the information on another page.
This will cause the information to live in two places.
Instead, link to the SSOT and explain why it is important to consume the information.

### Organize by topic, not by type

Beyond top-level audience-type folders (e.g. `administration`), we organize content by topic, not by type, so that it can be located as easily as possible within the single-source-of-truth (SSOT) section for the subject matter.

For example, do not create groupings of similar media types (e.g. glossaries, FAQs, or sets of all articles or videos).

Such grouping of content by type makes
it difficult to browse for the information you need and difficult to maintain up-to-date content.
Instead, organize content by its subject (e.g. everything related to CI goes together)
and cross-link between any related content.

### Docs-first methodology

We employ a **docs-first methodology** to help ensure that the docs remain a complete and trusted resource, and to make communicating about the use of GitLab more efficient.

- If the answer to a question exists in documentation, share the link to the docs instead of rephrasing the information.
- When you encounter new information not available in GitLab’s documentation (for example, when working on a support case or testing a feature), your first step should be to create a merge request to add this information to the docs. You can then share the MR in order to communicate this information.

New information that would be useful toward the future usage or troubleshooting of GitLab should not be written directly in a forum or other messaging system, but added to a docs MR and then referenced, as described above. Note that among any other doc changes, you can always add a Troubleshooting section to a doc if none exists, or un-comment and use the placeholder Troubleshooting section included as part of our [doc template](structure.md#template-for-new-docs), if present.

The more we reflexively add useful information to the docs, the more (and more successfully) the docs will be used to efficiently accomplish tasks and solve problems.

If you have questions when considering, authoring, or editing docs, ask the Technical Writing team on Slack in `#docs` or in GitLab by mentioning the writer for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages). Otherwise, forge ahead with your best effort. It does not need to be perfect; the team is happy to review and improve upon your content. Please review the [Documentation guidelines](index.md) before you begin your first documentation MR.

Having a knowledge base is any form that is separate from the documentation would be against the docs-first methodology because the content would overlap with the documentation.

## Markdown

All GitLab documentation is written using [Markdown](https://en.wikipedia.org/wiki/Markdown).

The [documentation website](https://docs.gitlab.com) uses GitLab Kramdown as its Markdown rendering engine. For a complete Kramdown reference, see the [GitLab Markdown Kramdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/).

The [`gitlab-kramdown`](https://gitlab.com/gitlab-org/gitlab_kramdown)
Ruby gem will support all [GFM markup](../../user/markdown.md) in the future. That is,
all markup that is supported for display in the GitLab application itself. For now,
use regular Markdown markup, following the rules in the linked style guide.

Note that Kramdown-specific markup (e.g., `{:.class}`) will not render properly on GitLab instances under [`/help`](index.md#gitlab-help).

Hard-coded HTML is valid, although it's discouraged to be used while we have `/help`. HTML is permitted as long as:

- There's no equivalent markup in markdown.
- Advanced tables are necessary.
- Special styling is required.
- Reviewed and approved by a technical writer.

### Markdown Rules

GitLab ensures that the Markdown used across all documentation is consistent, as
well as easy to review and maintain, by testing documentation changes with
[Markdownlint (mdl)](https://github.com/markdownlint/markdownlint). This lint test
checks many common problems with Markdown, and fails when any document has an issue
with Markdown formatting that may cause the page to render incorrectly within GitLab.
It will also fail when a document is using non-standard Markdown (which may render
correctly, but is not the current standard in GitLab documentation).

Each formatting issue that mdl checks has an associated [rule](https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md),
and the rules that are currently enabled for GitLab documentation are listed in the
[`.mdlrc.style`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.mdlrc.style) file.
Configuration options are set in the [`.mdlrc`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.mdlrc.style)
file.

## Structure

### Organize by topic, not by type

Because we want documentation to be a SSOT, we should [organize by topic, not by type](#organize-by-topic-not-by-type).

### Folder structure overview

The documentation is separated by top-level audience folders [`user`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/user),
[`administration`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/administration), and [`development`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/development) (contributing) folders.

Beyond that, we primarily follow the structure of the GitLab user interface or API.

Our goal is to have a clear hierarchical structure with meaningful URLs
like `docs.gitlab.com/user/project/merge_requests/`. With this pattern,
you can immediately tell that you are navigating to user-related documentation
about Project features; specifically about Merge Requests. Our site's paths match
those of our repository, so the clear structure also makes documentation easier to update.

The table below shows what kind of documentation goes where.

| Directory             | What belongs here      |
|:----------------------|:---------------------------------------------------------------------------------------------------------------------------------|
| `doc/user/`           | User related documentation. Anything that can be done within the GitLab UI goes here, including usage of the `/admin` interface. |
| `doc/administration/` | Documentation that requires the user to have access to the server where GitLab is installed. The admin settings that can be accessed via GitLab's interface exist under `doc/user/admin_area/`. |
| `doc/api/`            | API related documentation. |
| `doc/development/`    | Documentation related to the development of GitLab, whether contributing code or docs. Related process and style guides should go here. |
| `doc/legal/`          | Legal documents about contributing to GitLab. |
| `doc/install/`        | Contains instructions for installing GitLab. |
| `doc/update/`         | Contains instructions for updating GitLab. |
| `doc/topics/`         | Indexes per topic (`doc/topics/topic-name/index.md`): all resources for that topic. |

### Working with directories and files

1. When you create a new directory, always start with an `index.md` file.
   Do not use another file name and **do not** create `README.md` files.
1. **Do not** use special characters and spaces, or capital letters in file names,
   directory names, branch names, and anything that generates a path.
1. When creating a new document and it has more than one word in its name,
   make sure to use underscores instead of spaces or dashes (`-`). For example,
   a proper naming would be `import_projects_from_github.md`. The same rule
   applies to images.
1. For image files, do not exceed 100KB.
1. Do not upload video files to the product repositories.
   [Link or embed videos](#videos) instead.
1. There are four main directories, `user`, `administration`, `api` and `development`.
1. The `doc/user/` directory has five main subdirectories: `project/`, `group/`,
   `profile/`, `dashboard/` and `admin_area/`.
   1. `doc/user/project/` should contain all project related documentation.
   1. `doc/user/group/` should contain all group related documentation.
   1. `doc/user/profile/` should contain all profile related documentation.
      Every page you would navigate under `/profile` should have its own document,
      i.e. `account.md`, `applications.md`, `emails.md`, etc.
   1. `doc/user/dashboard/` should contain all dashboard related documentation.
   1. `doc/user/admin_area/` should contain all admin related documentation
      describing what can be achieved by accessing GitLab's admin interface
      (_not to be confused with `doc/administration` where server access is
      required_).
      1. Every category under `/admin/application_settings` should have its
         own document located at `doc/user/admin_area/settings/`. For example,
         the **Visibility and Access Controls** category should have a document
         located at `doc/user/admin_area/settings/visibility_and_access_controls.md`.
1. The `doc/topics/` directory holds topic-related technical content. Create
   `doc/topics/topic-name/subtopic-name/index.md` when subtopics become necessary.
   General user- and admin- related documentation, should be placed accordingly.
1. The directories `/workflow/`, `/university/`, and `/articles/` have
   been **deprecated** and the majority their docs have been moved to their correct location
   in small iterations.

If you are unsure where a document or a content addition should live, this should
not stop you from authoring and contributing. You can use your best judgment and
then ask the reviewer of your MR to confirm your decision, and/or ask a technical writer
at any stage in the process. The technical writing team will review all documentation
changes, regardless, and can move content if there is a better place for it.

### Avoid duplication

Do not include the same information in multiple places. [Link to a SSOT instead.](#link-instead-of-summarize)

### References across documents

- Give each folder an index.md page that introduces the topic, introduces the pages within, and links to the pages within (including to the index pages of any next-level subpaths).
- To ensure discoverability, ensure each new or renamed doc is linked from its higher-level index page and other related pages.
- When making reference to other GitLab products and features, link to their respective docs, at least on first mention.
- When making reference to third-party products or technologies, link out to their external sites, documentation, and resources.

### Structure within documents

- Include any and all applicable subsections as described on the [structure and template](structure.md) page.
- Structure content in alphabetical order in tables, lists, etc., unless there is
  a logical reason not to (for example, when mirroring the UI or an otherwise ordered sequence).

## Language

- Use inclusive language and avoid jargon, as well as uncommon
  words. The docs should be clear and easy to understand.
- Write in the 3rd person (use "we", "you", "us", "one", instead of "I" or "me").
- Be clear, concise, and stick to the goal of the doc.
- Write in US English.
- Capitalize "G" and "L" in GitLab.
- Use title case when referring to [features](https://about.gitlab.com/features/) or
  [products](https://about.gitlab.com/pricing/) (e.g., GitLab Runner, Geo,
  Issue Boards, GitLab Core, Git, Prometheus, Kubernetes, etc), and methods or methodologies
  (e.g., Continuous Integration, Continuous Deployment, Scrum, Agile, etc). Note that
  some features are also objects (e.g. "GitLab's Merge Requests support X." and "Create a new merge request for Z.").

## Text

- [Write in markdown](#markdown).
- Splitting long lines (preferably up to 100 characters) can make it easier to provide feedback on small chunks of text.
- Insert an empty line for new paragraphs.
- Use sentence case for titles, headings, labels, menu items, and buttons.
- Insert an empty line between different markups (e.g., after every paragraph, header, list, etc). Example:

    ```md
    ## Header

    Paragraph.

    - List item 1
    - List item 2
    ```

### Tables overlapping the TOC

By default, all tables have a width of 100% on docs.gitlab.com.
In a few cases, the table will overlap the table of contents (ToC).
For these cases, add an entry to the document's frontmatter to
render them displaying block. This will make sure the table
is displayed behind the ToC, scrolling horizontally:

```md
---
table_display_block: true
---
```

## Emphasis

- Use double asterisks (`**`) to mark a word or text in bold (`**bold**`).
- Use underscore (`_`) for text in italics (`_italic_`).
- Use greater than (`>`) for blockquotes.

## Punctuation

Check the general punctuation rules for the GitLab documentation on the table below.
Check specific punctuation rules for [list items](#list-items) below.

| Rule | Example |
| ---- | ------- |
| Always end full sentences with a period. | _For a complete overview, read through this document._|
| Always add a space after a period when beginning a new sentence | _For a complete overview, check this doc. For other references, check out this guide._ |
| Do not use double spaces. | --- |
| Do not use tabs for indentation. Use spaces instead. You can configure your code editor to output spaces instead of tabs when pressing the tab key. | --- |
| Use serial commas ("Oxford commas") before the final 'and/or' in a list. | _You can create new issues, merge requests, and milestones._ |
| Always add a space before and after dashes when using it in a sentence (for replacing a comma, for example). | _You should try this - or not._ |
| Always use lowercase after a colon. | _Related Issues: a way to create a relationship between issues._ |

## List items

- Always start list items with a capital letter.
- Always leave a blank line before and after a list.
- Begin a line with spaces (not tabs) to denote a subitem.
- To nest subitems, indent them with two spaces.
- To nest code blocks, indent them with four spaces.
- Only use ordered lists when their items describe a sequence of steps to follow.

**Markup:**

- Use dashes (`-`) for unordered lists instead of asterisks (`*`).
- Use the number one (`1`) for each item in an ordered list.
  When rendered, the list items will appear with sequential numbering.

**Punctuation:**

- Do not add commas (`,`) or semicolons (`;`) to the end of a list item.
- Only add periods to the end of a list item if the item consists of a complete sentence. The [definition of full sentence](https://www2.le.ac.uk/offices/ld/resources/writing/grammar/grammar-guides/sentence) is: _"a complete sentence always contains a verb, expresses a complete idea, and makes sense standing alone"_.
- Be consistent throughout the list: if the majority of the items do not end in a period, do not end any of the items in a period, even if they consist of a complete sentence. The opposite is also valid: if the majority of the items end with a period, end all with a period.
- Separate list items from explanatory text with a colon (`:`). For example:

    ```md
    The list is as follows:

    - First item: this explains the first item.
    - Second item: this explains the second item.
    ```

**Examples:**

Do:

- First list item
- Second list item
- Third list item

Don't:

- First list item
- Second list item
- Third list item.

Do:

- Let's say this is a complete sentence.
- Let's say this is also a complete sentence.
- Not a complete sentence.

Don't:

- Let's say this is a complete sentence.
- Let's say this is also a complete sentence.
- Not a complete sentence

## Quotes

Valid for markdown content only, not for frontmatter entries:

- Standard quotes: double quotes (`"`). Example: "This is wrapped in double quotes".
- Quote within a quote: double quotes (`"`) wrap single quotes (`'`). Example: "I am 'quoting' something within a quote".

For other punctuation rules, please refer to the
[GitLab UX guide](https://design.gitlab.com/content/punctuation/).

## Headings

- Add **only one H1** in each document, by adding `#` at the beginning of
  it (when using markdown). The `h1` will be the document `<title>`.
- Start with an `h2` (`##`), and respect the order `h2` > `h3` > `h4` > `h5` > `h6`.
  Never skip the hierarchy level, such as `h2` > `h4`
- Avoid putting numbers in headings. Numbers shift, hence documentation anchor
  links shift too, which eventually leads to dead links. If you think it is
  compelling to add numbers in headings, make sure to at least discuss it with
  someone in the Merge Request.
- [Avoid using symbols and special chars](https://gitlab.com/gitlab-org/gitlab-docs/issues/84)
  in headers. Whenever possible, they should be plain and short text.
- Avoid adding things that show ephemeral statuses. For example, if a feature is
  considered beta or experimental, put this info in a note, not in the heading.
- When introducing a new document, be careful for the headings to be
  grammatically and syntactically correct. Mention an [assigned technical writer (TW)](https://about.gitlab.com/handbook/product/categories/)
  for review.
  This is to ensure that no document with wrong heading is going
  live without an audit, thus preventing dead links and redirection issues when
  corrected.
- Leave exactly one new line after a heading.
- Do not use links in headings.
- Add the corresponding [product badge](#product-badges) according to the tier the feature belongs.

## Links

- Use inline link markdown markup `[Text](https://example.com)`.
  It's easier to read, review, and maintain. **Do not** use `[Text][identifier]`.
- To link to internal documentation, use relative links, not full URLs. Use `../` to
  navigate to high-level directories, and always add the file name `file.md` at the
  end of the link with the `.md` extension, not `.html`.
  Example: instead of `[text](../../merge_requests/)`, use
  `[text](../../merge_requests/index.md)` or, `[text](../../ci/README.md)`, or,
  for anchor links, `[text](../../ci/README.md#examples)`.
  Using the markdown extension is necessary for the [`/help`](index.md#gitlab-help)
  section of GitLab.
- To link from CE to EE-only documentation, use the EE-only doc full URL.
- Use [meaningful anchor texts](https://www.futurehosting.com/blog/links-should-have-meaningful-anchor-text-heres-why/).
  E.g., instead of writing something like `Read more about GitLab Issue Boards [here](LINK)`,
  write `Read more about [GitLab Issue Boards](LINK)`.

### Links requiring permissions

Don't link directly to:

- [Confidential issues](../../user/project/issues/confidential_issues.md).
- Project features that require [special permissions](../../user/permissions.md) to view.

These will fail for:

- Those without sufficient permissions.
- Automated link checkers.

Instead:

- To reduce confusion, mention in the text that the information is either:
  - Contained in a confidential issue.
  - Requires special permission to a project to view.
- Provide a link in back ticks (`` ` ``) so that those with access to the issue can easily navigate to it.

Example:

```md
For more information, see the [confidential issue](../../user/project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab-ce/issues/<issue_number>`.
```

### Unlinking emails

By default, all email addresses will render in an email tag on docs.gitlab.com.
To escape the code block and unlink email addresses, use two backticks:

```md
`` example@email.com ``
```

## Navigation

To indicate the steps of navigation through the UI:

- Use the exact word as shown in the UI, including any capital letters as-is.
- Use bold text for navigation items and the char "greater than" (`>`) as separator
  (e.g., `Navigate to your project's **Settings > CI/CD**` ).
- If there are any expandable menus, make sure to mention that the user
  needs to expand the tab to find the settings you're referring to (e.g., `Navigate to your project's **Settings > CI/CD** and expand **General pipelines**`).

## Images

- Place images in a separate directory named `img/` in the same directory where
  the `.md` document that you're working on is located.
- Images should have a specific, non-generic name that will
  differentiate and describe them properly.
- Always add to the end of the file name the GitLab release version
  number corresponding to the release milestone the image was added to,
  or corresponding to the release the screenshot was taken from, using the
  format `image_name_vX_Y.png`.
  ([Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/61027) in GitLab 12.1.)
- For example, for a screenshot taken from the pipelines page of
  GitLab 11.1, a valid name is `pipelines_v11_1.png`. If you're
  adding an illustration that does not include parts of the UI,
  add the release number corresponding to the release the image
  was added to. Example, for an MR added to 11.1's milestone,
  a valid name for an illustration is `devops_diagram_v11_1.png`.
- Keep all file names in lower case.
- Consider using PNG images instead of JPEG.
- Compress all images with <https://tinypng.com/> or similar tool.
- Compress gifs with <https://ezgif.com/optimize> or similar tool.
- Images should be used (only when necessary) to _illustrate_ the description
  of a process, not to _replace_ it.
- Max image size: 100KB (gifs included).
- See also how to link and embed [videos](#videos) to illustrate the docs.

Inside the document:

- The Markdown way of using an image inside a document is:
  `![Proper description what the image is about](img/document_image_title_vX_Y.png)`
- Always use a proper description for what the image is about. That way, when a
  browser fails to show the image, this text will be used as an alternative
  description.
- If there are consecutive images with little text between them, always add
  three dashes (`---`) between the image and the text to create a horizontal
  line for better clarity.
- If a heading is placed right after an image, always add three dashes (`---`)
  between the image and the heading.

### Remove image shadow

All images displayed on docs.gitlab.com have a box shadow by default.
To remove the box shadow, use the image class `.image-noshadow` applied
directly to an HTML `img` tag:

```html
<img src="path/to/image.jpg" alt="Alt text (required)" class="image-noshadow">
```

## Videos

Adding GitLab's existing YouTube video tutorials to the documentation is
highly encouraged, unless the video is outdated. Videos should not
replace documentation, but complement or illustrate it. If content in a video is
fundamental to a feature and its key use cases, but this is not adequately covered in the documentation,
add this detail to the documentation text or create an issue to review the video and do so.

Do not upload videos to the product repositories. [Link](#link-to-video) or [embed](#embed-videos) them instead.

### Link to video

To link out to a video, include a YouTube icon so that readers can
quickly and easily scan the page for videos before reading:

```md
<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Video Title](link-to-video).
```

You can link any up-to-date video that is useful to the GitLab user.

### Embed videos

> [Introduced](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/472) in GitLab 12.1.

GitLab docs (docs.gitlab.com) support embedded videos.

You can only embed videos from
[GitLab's official YouTube account](https://www.youtube.com/channel/UCnMGQ8QHMAnVIsI3xJrihhg).
For videos from other sources, [link](#link-to-video) them instead.

In most cases, it is better to [link to video](#link-to-video) instead,
because an embed takes up a lot of space on the page and can be distracting
to readers.

To embed a video, follow the instructions below and make sure
you have your MR reviewed and approved by a technical writer.

1. Copy the code below and paste it into your markdown file.
  Leave a blank line above and below it. Do NOT edit the code
  (don't remove or add any spaces, etc).
1. On YouTube, visit the video URL you want to display. Copy
  the regular URL from your browser (`https://www.youtube.com/watch?v=VIDEO-ID`)
  and replace the video title and link in the line under `<div class="video-fallback">`.
1. On YouTube, click **Share**, then **Embed**.
1. Copy the `<iframe>` source (`src`) **URL only**
  (`https://www.youtube.com/embed/VIDEO-ID`),
  and paste it, replacing the content of the `src` field in the
  `iframe` tag.

```html
leave a blank line here
<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=MqL6BMOySIQ">Video title</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/MqL6BMOySIQ" frameborder="0" allowfullscreen="true"> </iframe>
</figure>
leave a blank line here
```

This is how it renders on docs.gitlab.com:

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=enMumwvLAug">What is GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/MqL6BMOySIQ" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

> Notes:
>
> - The `figure` tag is required for semantic SEO and the `video_container`
class is necessary to make sure the video is responsive and displays
nicely on different mobile devices.
> - The `<div class="video-fallback">` is a fallback necessary for GitLab's
`/help`, as GitLab's markdown processor does not support iframes. It's hidden on the docs site but will be displayed on GitLab's `/help`.

## Code blocks

- Always wrap code added to a sentence in inline code blocks (``` ` ```).
  E.g., `.gitlab-ci.yml`, `git add .`, `CODEOWNERS`, `only: master`.
  File names, commands, entries, and anything that refers to code should be added to code blocks.
  To make things easier for the user, always add a full code block for things that can be
  useful to copy and paste, as they can easily do it with the button on code blocks.
- For regular code blocks, always use a highlighting class corresponding to the
  language for better readability. Examples:

  ````md
  ```ruby
  Ruby code
  ```

  ```js
  JavaScript code
  ```

  ```md
  Markdown code
  ```

  ```text
  Code for which no specific highlighting class is available.
  ```
  ````

- To display raw markdown instead of rendered markdown, use four backticks on their own lines around the
  markdown to display. See [example](https://gitlab.com/gitlab-org/gitlab-ce/blob/8c1991b9bb7e3b8d606481fdea316d633cfa5eb7/doc/development/documentation/styleguide.md#L275-287).
- For a complete reference on code blocks, check the [Kramdown guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/#code-blocks).

## Alert boxes

Whenever you need to call special attention to particular sentences,
use the following markup for highlighting.

_Note that the alert boxes only work for one paragraph only. Multiple paragraphs,
lists, headers, etc will not render correctly. For multiple lines, use blockquotes instead._

### Note

Notes catch the eye of most readers, and therefore should be used very sparingly.
In most cases, content considered for a note should be included:

- As just another sentence in the previous paragraph or the most-relevant paragraph.
- As its own standalone paragraph.
- As content under a new subheading that introduces the topic, making it more visible/findable.

#### When to use

Use a note when there is a reason that most or all readers who browse the
section should see the content. That is, if missed, it’s likely to cause 
major trouble for a minority of users or significant trouble for a majority
of users.

Weigh the costs of distracting users to whom the content is not relevant against
the cost of users missing the content if it were not expressed as a note.

```md
NOTE: **Note:**
This is something to note.
```

How it renders in docs.gitlab.com:

NOTE: **Note:**
This is something to note.

### Tip

```md
TIP: **Tip:**
This is a tip.
```

How it renders in docs.gitlab.com:

TIP: **Tip:**
This is a tip.

### Caution

```md
CAUTION: **Caution:**
This is something to be cautious about.
```

How it renders in docs.gitlab.com:

CAUTION: **Caution:**
This is something to be cautious about.

### Danger

```md
DANGER: **Danger:**
This is a breaking change, a bug, or something very important to note.
```

How it renders in docs.gitlab.com:

DANGER: **Danger:**
This is a breaking change, a bug, or something very important to note.

## Blockquotes

For highlighting a text within a blue blockquote, use this format:

```md
> This is a blockquote.
```

which renders in docs.gitlab.com to:

> This is a blockquote.

If the text spans across multiple lines it's OK to split the line.

For multiple paragraphs, use the symbol `>` before every line:

```md
> This is the first paragraph.
>
> This is the second paragraph.
>
> - This is a list item
> - Second item in the list
>
> ### This is an `h3`
```

Which renders to:

> This is the first paragraph.
>
> This is the second paragraph.
>
> - This is a list item
> - Second item in the list
>
> ### This is an `h3`
>{:.no_toc}

## Terms

To maintain consistency through GitLab documentation, the following guides documentation authors
on agreed styles and usage of terms.

### Describing UI elements

The following are styles to follow when describing UI elements on a screen:

- For elements with a visible label, use that label in bold with matching case. For example, `the **Cancel** button`.
- For elements with a tooltip or hover label, use that label in bold with matching case. For example, `the **Add status emoji** button`.

### Verbs for UI elements

The following are recommended verbs for specific uses.

| Recommended | Used for                   | Alternatives               |
|:------------|:---------------------------|:---------------------------|
| "click"     | buttons, links, menu items | "hit", "press", "select"   |
| "check"     | checkboxes                 | "enable", "click", "press" |
| "select"    | dropdowns                  | "pick"                     |
| "expand"    | expandable sections        | "open"                     |

### Other Verbs

| Recommended | Used for                        | Alternatives       |
|:------------|:--------------------------------|:-------------------|
| "go"        | making a browser go to location | "navigate", "open" |

## GitLab versions and tiers

Tagged and released versions of GitLab documentation are available:

- In the [documentation archives](https://docs.gitlab.com/archives/).
- At the `/help` URL for any GitLab installation.

The version introducing a new feature is added to the top of the topic in the documentation to provide
a helpful link back to how the feature was developed.

### Text for documentation requiring version text

- For features that need to declare the GitLab version that the feature was introduced. Text similar
  to the following should be added immediately below the heading as a blockquote:

    ```md
    > Introduced in GitLab 11.3.
    ```

- Whenever possible, version text should have a link to the issue, merge request, or epic that introduced the feature.
  An issue is preferred over a merge request, and a merge request is preferred over an epic. For example:

    ```md
    > [Introduced](<link-to-issue>) in GitLab 11.3.
    ```

- If the feature is only available in GitLab Enterprise Edition, mention
  the [paid tier](https://about.gitlab.com/handbook/marketing/product-marketing/#tiers)
  the feature is available in:

    ```md
    > [Introduced](<link-to-issue>) in [GitLab Starter](https://about.gitlab.com/pricing/) 11.3.
    ```

### Removing version text

Over time, version text will reference a progressively older version of GitLab. In cases where version text
refers to versions of GitLab four or more major versions back, consider removing the text.

For example, if the current major version is 11.x, version text referencing versions of GitLab 7.x
and older are candidates for removal.

NOTE: **Note:**
This guidance applies to any text that mentions a GitLab version, not just "Introduced in... " text.
Other text includes deprecation notices and version-specific how-to information.

## Product badges

When a feature is available in EE-only tiers, add the corresponding tier according to the
feature availability:

- For GitLab Starter and GitLab.com Bronze: `**(STARTER)**`.
- For GitLab Premium and GitLab.com Silver: `**(PREMIUM)**`.
- For GitLab Ultimate and GitLab.com Gold: `**(ULTIMATE)**`.
- For GitLab Core and GitLab.com Free: `**(CORE)**`.

To exclude GitLab.com tiers (when the feature is not available in GitLab.com), add the
keyword "only":

- For GitLab Core: `**(CORE ONLY)**`.
- For GitLab Starter: `**(STARTER ONLY)**`.
- For GitLab Premium: `**(PREMIUM ONLY)**`.
- For GitLab Ultimate: `**(ULTIMATE ONLY)**`.

For GitLab.com only tiers (when the feature is not available for self-hosted instances):

- For GitLab Bronze and higher tiers: `**(BRONZE ONLY)**`.
- For GitLab Silver and higher tiers: `**(SILVER ONLY)**`.
- For GitLab Gold: `**(GOLD ONLY)**`.

The tier should be ideally added to headers, so that the full badge will be displayed.
However, it can be also mentioned from paragraphs, list items, and table cells. For these cases,
the tier mention will be represented by an orange question mark that will show the tiers on hover.

For example:

- `**(STARTER)**` renders as **(STARTER)**
- `**(STARTER ONLY)**` renders as **(STARTER ONLY)**
- `**(SILVER ONLY)**` renders as **(SILVER ONLY)**

The absence of tiers' mentions mean that the feature is available in GitLab Core,
GitLab.com Free, and all higher tiers.

### How it works

Introduced by [!244](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/244),
the special markup `**(STARTER)**` will generate a `span` element to trigger the
badges and tooltips (`<span class="badge-trigger starter">`). When the keyword
"only" is added, the corresponding GitLab.com badge will not be displayed.

## Specific sections

Certain styles should be applied to specific sections. Styles for specific sections are outlined below.

### GitLab Restart

There are many cases that a restart/reconfigure of GitLab is required. To
avoid duplication, link to the special document that can be found in
[`doc/administration/restart_gitlab.md`][doc-restart]. Usually the text will
read like:

```md
Save the file and [reconfigure GitLab](../../administration/restart_gitlab.md)
for the changes to take effect.
```

If the document you are editing resides in a place other than the GitLab CE/EE
`doc/` directory, instead of the relative link, use the full path:
`https://docs.gitlab.com/ce/administration/restart_gitlab.html`.
Replace `reconfigure` with `restart` where appropriate.

### Installation guide

**Ruby:**
In [step 2 of the installation guide](../../install/installation.md#2-ruby),
we install Ruby from source. Whenever there is a new version that needs to
be updated, remember to change it throughout the codeblock and also replace
the sha256sum (it can be found in the [downloads page][ruby-dl] of the Ruby
website).

[ruby-dl]: https://www.ruby-lang.org/en/downloads/ "Ruby download website"

### Configuration documentation for source and Omnibus installations

GitLab currently officially supports two installation methods: installations
from source and Omnibus packages installations.

Whenever there is a setting that is configurable for both installation methods,
prefer to document it in the CE docs to avoid duplication.

Configuration settings include:

1. Settings that touch configuration files in `config/`.
1. NGINX settings and settings in `lib/support/` in general.

When there is a list of steps to perform, usually that entails editing the
configuration file and reconfiguring/restarting GitLab. In such case, follow
the style below as a guide:

```md
**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    external_url "https://gitlab.example.com"
    ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.

---

**For installations from source**

1. Edit `config/gitlab.yml`:

    ```yaml
    gitlab:
      host: "gitlab.example.com"
    ```

1. Save the file and [restart] GitLab for the changes to take effect.


[reconfigure]: path/to/administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: path/to/administration/restart_gitlab.md#installations-from-source
```

In this case:

- Before each step list the installation method is declared in bold.
- Three dashes (`---`) are used to create a horizontal line and separate the
  two methods.
- The code blocks are indented one or more spaces under the list item to render
  correctly.
- Different highlighting languages are used for each config in the code block.
- The [GitLab Restart](#gitlab-restart) section is used to explain a required restart/reconfigure of GitLab.

## API

Here is a list of must-have items. Use them in the exact order that appears
on this document. Further explanation is given below.

- Every method must have the REST API request. For example:

    ```
    GET /projects/:id/repository/branches
    ```

- Every method must have a detailed
  [description of the parameters](#method-description).
- Every method must have a cURL example.
- Every method must have a response body (in JSON format).

### API topic template

The following can be used as a template to get started:

````md
## Descriptive title

One or two sentence description of what endpoint does.

```text
METHOD /endpoint
```

| Attribute   | Type     | Required | Description           |
|:------------|:---------|:---------|:----------------------|
| `attribute` | datatype | yes/no   | Detailed description. |
| `attribute` | datatype | yes/no   | Detailed description. |

Example request:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" 'https://gitlab.example.com/api/v4/endpoint?parameters'
```

Example response:

```json
[
  {
  }
]
```
````

### Fake tokens

There may be times where a token is needed to demonstrate an API call using
cURL or a variable used in CI. It is strongly advised not to use real
tokens in documentation even if the probability of a token being exploited is
low.

You can use the following fake tokens as examples.

| Token type            | Token value                                                        |
|:----------------------|:-------------------------------------------------------------------|
| Private user token    | `<your_access_token>`                                             |
| Personal access token | `n671WNGecHugsdEDPsyo`                                             |
| Application ID        | `2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6` |
| Application secret    | `04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df` |
| CI/CD variable        | `Li8j-mLUVA3eZYjPfd_H`                                             |
| Specific Runner token | `yrnZW46BrtBFqM7xDzE7dddd`                                         |
| Shared Runner token   | `6Vk7ZsosqQyfreAxXTZr`                                             |
| Trigger token         | `be20d8dcc028677c931e04f3871a9b`                                   |
| Webhook secret token  | `6XhDroRcYPM5by_h-HLY`                                             |
| Health check token    | `Tu7BgjR9qeZTEyRzGG2P`                                             |
| Request profile token | `7VgpS4Ax5utVD2esNstz`                                             |

### Method description

Use the following table headers to describe the methods. Attributes should
always be in code blocks using backticks (``` ` ```).

```md
| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
```

Rendered example:

| Attribute | Type   | Required | Description         |
|:----------|:-------|:---------|:--------------------|
| `user`    | string | yes      | The GitLab username |

### cURL commands

- Use `https://gitlab.example.com/api/v4/` as an endpoint.
- Wherever needed use this personal access token: `<your_access_token>`.
- Always put the request first. `GET` is the default so you don't have to
  include it.
- Use double quotes to the URL when it includes additional parameters.
- Prefer to use examples using the personal access token and don't pass data of
  username and password.

| Methods                                    | Description                                           |
|:-------------------------------------------|:------------------------------------------------------|
| `-H "PRIVATE-TOKEN: <your_access_token>"`  | Use this method as is, whenever authentication needed |
| `-X POST`                                  | Use this method when creating new objects             |
| `-X PUT`                                   | Use this method when updating existing objects        |
| `-X DELETE`                                | Use this method when removing existing objects        |

### cURL Examples

Below is a set of [cURL][] examples that you can use in the API documentation.

#### Simple cURL command

Get the details of a group:

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/gitlab-org
```

#### cURL example with parameters passed in the URL

Create a new project under the authenticated user's namespace:

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?name=foo"
```

#### Post data using cURL's --data

Instead of using `-X POST` and appending the parameters to the URI, you can use
cURL's `--data` option. The example below will create a new project `foo` under
the authenticated user's namespace.

```bash
curl --data "name=foo" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

#### Post data using JSON content

> **Note:** In this example we create a new group. Watch carefully the single
and double quotes.

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{"path": "my-group", "name": "My group"}' https://gitlab.example.com/api/v4/groups
```

#### Post data using form-data

Instead of using JSON or urlencode you can use multipart/form-data which
properly handles data encoding:

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "title=ssh-key" --form "key=ssh-rsa AAAAB3NzaC1yc2EA..." https://gitlab.example.com/api/v4/users/25/keys
```

The above example is run by and administrator and will add an SSH public key
titled ssh-key to user's account which has an id of 25.

#### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Observe how spaces are escaped using the `%20`
ASCII code.

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

#### Pass arrays to API calls

The GitLab API sometimes accepts arrays of strings or integers. For example, to
restrict the sign-up e-mail domains of a GitLab instance to `*.example.com` and
`example.net`, you would do something like this:

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "domain_whitelist[]=*.example.com" --data "domain_whitelist[]=example.net" https://gitlab.example.com/api/v4/application/settings
```

[cURL]: http://curl.haxx.se/ "cURL website"
[single spaces]: http://www.slate.com/articles/technology/technology/2011/01/space_invaders.html
[gfm]: https://docs.gitlab.com/ce/user/markdown.html#newlines "GitLab flavored markdown documentation"
[ce-1242]: https://gitlab.com/gitlab-org/gitlab-ce/issues/1242
[doc-restart]: ../../administration/restart_gitlab.md "GitLab restart documentation"
