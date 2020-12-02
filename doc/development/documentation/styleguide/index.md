---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: 'Writing styles, markup, formatting, and other standards for GitLab Documentation.'
---

# Documentation Style Guide

This document defines the standards for GitLab documentation.

For broader information about the documentation, see the [Documentation guidelines](../index.md).

For guidelines specific to text in the GitLab interface, see the Pajamas [Content](https://design.gitlab.com/content/error-messages/) section.

For information on how to validate styles locally or by using GitLab CI/CD, see [Testing](../testing.md).

Use this guide for standards on grammar, formatting, word usage, and more.

You can also view a list of [recent updates to this guide](https://gitlab.com/dashboard/merge_requests?scope=all&utf8=%E2%9C%93&state=merged&label_name[]=tw-style&not[label_name][]=docs%3A%3Afix).

If you can't find what you need:

- View the GitLab Handbook for [writing style guidelines](https://about.gitlab.com/handbook/communication/#writing-style-guidelines) that apply to all GitLab content.
- Refer to one of the following:

  - [Microsoft Style Guide](https://docs.microsoft.com/en-us/style-guide/welcome/).
  - [Google Developer Documentation Style Guide](https://developers.google.com/style).

If you have questions about style, mention `@tw-style` in an issue or merge request, or, if you have access to the GitLab Slack workspace, use `#docs-process`.

## Documentation is the single source of truth (SSOT)

### Why a single source of truth

The documentation of GitLab products and features is the SSOT for all
information related to implementation, usage, and troubleshooting. It evolves
continuously, in keeping with new products and features, and with improvements
for clarity, accuracy, and completeness.

This policy prevents information silos, making it easier to find information
about GitLab products.

It also informs decisions about the kinds of content we include in our
documentation.

### All information

Include problem-solving actions that may address rare cases or be considered
_risky_, so long as proper context is provided in the form of fully detailed
warnings and caveats. This kind of content should be included as it could be
helpful to others and, when properly explained, its benefits outweigh the risks.
If you think you have found an exception to this rule, contact the
Technical Writing team.

GitLab adds all troubleshooting information to the documentation, no matter how
unlikely a user is to encounter a situation. For the [Troubleshooting sections](#troubleshooting),
people in GitLab Support can merge additions themselves.

### All media types

Include any media types/sources if the content is relevant to readers. You can
freely include or link presentations, diagrams, videos, and so on; no matter who
it was originally composed for, if it is helpful to any of our audiences, we can
include it.

- If you use an image that has a separate source file (for example, a vector or
  diagram format), link the image to the source file so that it may be reused or
  updated by anyone.
- Do not copy and paste content from other sources unless it is a limited
  quotation with the source cited. Typically it is better to either rephrase
  relevant information in your own words or link out to the other source.

### No special types

In the software industry, it is a best practice to organize documentation in
different types. For example, [Divio recommends](https://www.divio.com/blog/documentation/):

- Tutorials
- How-to guides
- Explanation
- Reference (for example, a glossary)

At GitLab, we have so many product changes in our monthly releases that we can't
afford to continuously update multiple types of information. If we have multiple
types, the information becomes outdated. Therefore, we have a
[single template](../structure.md) for documentation.

We currently do not distinguish specific document types, although we are open to
reconsidering this policy after the documentation has reached a future stage of
maturity and quality. If you are reading this, then despite our continuous
improvement efforts, that point hasn't been reached.

### Link instead of summarize

There is a temptation to summarize the information on another page, which
causes the information to live in two places. Instead, link to the single source
of truth and explain why it is important to consume the information.

### Organize by topic, not by type

Beyond top-level audience-type folders (for example, `administration`), we
organize content by topic, not by type, so it can be located in the
single-source-of-truth (SSOT) section for the subject matter.

For example, do not create groupings of similar media types. For example:

- Glossaries.
- FAQs.
- Sets of all articles or videos.

Such grouping of content by type makes it difficult to browse for the information
you need and difficult to maintain up-to-date content. Instead, organize content
by its subject (for example, everything related to CI goes together) and
cross-link between any related content.

### Docs-first methodology

We employ a _documentation-first methodology_ to help ensure the documentation
remains a complete and trusted resource, and to make communicating about the use
of GitLab more efficient.

- If the answer to a question exists in documentation, share the link to the
  documentation instead of rephrasing the information.
- When you encounter new information not available in GitLab’s documentation (for
  example, when working on a support case or testing a feature), your first step
  should be to create a merge request (MR) to add this information to the
  documentation. You can then share the MR to communicate this information.

New information that would be useful toward the future usage or troubleshooting
of GitLab should not be written directly in a forum or other messaging system,
but added to a documentation merge request and then referenced, as described above. Note
that among any other documentation changes, you can either:

- Add a [Troubleshooting section](#troubleshooting) to a doc if none exists.
- Un-comment and use the placeholder Troubleshooting section included as part of
  our [documentation template](../structure.md#template-for-new-docs), if present.

The more we reflexively add useful information to the documentation, the more
the documentation helps others efficiently accomplish
tasks and solve problems.

If you have questions when considering, authoring, or editing documentation, ask
the Technical Writing team. They're available on Slack in `#docs` or in GitLab by mentioning the
writer for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/product-categories/#devops-stages).
Otherwise, forge ahead with your best effort. It does not need to be perfect;
the team is happy to review and improve upon your content. Review the
[Documentation guidelines](index.md) before you begin your first documentation MR.

Having a knowledge base in any form that's separate from the documentation would
be against the documentation-first methodology, because the content would overlap with
the documentation.

## Markdown

All GitLab documentation is written using [Markdown](https://en.wikipedia.org/wiki/Markdown).

The [documentation website](https://docs.gitlab.com) uses GitLab Kramdown as its
Markdown rendering engine. For a complete Kramdown reference, see the
[GitLab Markdown Kramdown Guide](https://about.gitlab.com/handbook/markdown-guide/).

The [`gitlab-kramdown`](https://gitlab.com/gitlab-org/gitlab_kramdown) Ruby gem
plans to support all [GitLab Flavored Markdown](../../../user/markdown.md) in the future, which is
all Markdown supported for display in the GitLab application itself. For now, use
regular Markdown, following the rules in the linked style guide.

Kramdown-specific markup (for example, `{:.class}`) doesn't render
properly on GitLab instances under [`/help`](../index.md#gitlab-help).

### HTML in Markdown

Hard-coded HTML is valid, although it's discouraged from being used while we
have `/help`. HTML is permitted if:

- There's no equivalent markup in Markdown.
- Advanced tables are necessary.
- Special styling is required.
- Reviewed and approved by a technical writer.

### Markdown Rules

GitLab ensures that the Markdown used across all documentation is consistent, as
well as easy to review and maintain, by [testing documentation changes](../testing.md)
with [markdownlint](../testing.md#markdownlint). This lint test fails when any
document has an issue with Markdown formatting that may cause the page to render
incorrectly within GitLab. It also fails when a document has
non-standard Markdown (which may render correctly, but is not the current
standard for GitLab documentation).

#### Markdown rule `MD044/proper-names` (capitalization)

A rule that could cause confusion is `MD044/proper-names`, as it might not be
immediately clear what caused markdownlint to fail, or how to correct the
failure. This rule checks a list of known words, listed in the `.markdownlint.json`
file in each project, to verify proper use of capitalization and backticks.
Words in backticks are ignored by markdownlint.

In general, product names should follow the exact capitalization of the official
names of the products, protocols, and so on. See [`.markdownlint.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.markdownlint.json)
for the words tested for proper capitalization in GitLab documentation.

Some examples fail if incorrect capitalization is used:

- MinIO (needs capital `IO`)
- NGINX (needs all capitals)
- runit (needs lowercase `r`)

Additionally, commands, parameters, values, filenames, and so on must be
included in backticks. For example:

- "Change the `needs` keyword in your `.gitlab.yml`..."
  - `needs` is a parameter, and `.gitlab.yml` is a file, so both need backticks.
    Additionally, `.gitlab.yml` without backticks fails markdownlint because it
    does not have capital G or L.
- "Run `git clone` to clone a Git repository..."
  - `git clone` is a command, so it must be lowercase, while Git is the product,
    so it must have a capital G.

## Structure

Because we want documentation to be a SSOT, we should [organize by topic, not by
type](#organize-by-topic-not-by-type).

### Folder structure overview

The documentation is separated by top-level audience folders [`user`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/user),
[`administration`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/administration),
and [`development`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/doc/development)
(contributing) folders.

Beyond that, we primarily follow the structure of the GitLab user interface or
API.

Our goal is to have a clear hierarchical structure with meaningful URLs like
`docs.gitlab.com/user/project/merge_requests/`. With this pattern, you can
immediately tell that you are navigating to user-related documentation about
Project features; specifically about Merge Requests. Our site's paths match
those of our repository, so the clear structure also makes documentation easier
to update.

Put files for a specific product area into the related folder:

| Directory             | What belongs here |
|:----------------------|:------------------|
| `doc/user/`           | User related documentation. Anything that can be done within the GitLab user interface goes here, including usage of the `/admin` interface. |
| `doc/administration/` | Documentation that requires the user to have access to the server where GitLab is installed. Administrator settings in the GitLab user interface are under `doc/user/admin_area/`. |
| `doc/api/`            | API-related documentation. |
| `doc/development/`    | Documentation related to the development of GitLab, whether contributing code or documentation. Related process and style guides should go here. |
| `doc/legal/`          | Legal documents about contributing to GitLab. |
| `doc/install/`        | Contains instructions for installing GitLab. |
| `doc/update/`         | Contains instructions for updating GitLab. |
| `doc/topics/`         | Indexes per topic (`doc/topics/topic_name/index.md`): all resources for that topic. |

### Work with directories and files

Refer to the following items when working with directories and files:

1. When you create a new directory, always start with an `index.md` file.
   Don't use another filename and _do not_ create `README.md` files.
1. _Do not_ use special characters and spaces, or capital letters in file
   names, directory names, branch names, and anything that generates a path.
1. When creating or renaming a file or directory and it has more than one word
   in its name, use underscores (`_`) instead of spaces or dashes. For example,
   proper naming would be `import_project/import_from_github.md`. This applies
   to both image files and Markdown files.
1. For image files, do not exceed 100KB.
1. Do not upload video files to the product repositories.
   [Link or embed videos](#videos) instead.
1. There are four main directories: `user`, `administration`, `api`, and
   `development`.
1. The `doc/user/` directory has five main subdirectories: `project/`, `group/`,
   `profile/`, `dashboard/` and `admin_area/`.
   - `doc/user/project/` should contain all project related documentation.
   - `doc/user/group/` should contain all group related documentation.
   - `doc/user/profile/` should contain all profile related documentation.
     Every page you would navigate under `/profile` should have its own document,
     for example, `account.md`, `applications.md`, or `emails.md`.
   - `doc/user/dashboard/` should contain all dashboard related documentation.
   - `doc/user/admin_area/` should contain all administrator-related
     documentation describing what can be achieved by accessing the GitLab
     administrator interface (not to be confused with `doc/administration` where
     server access is required).
     - Every category under `/admin/application_settings/` should have its
      own document located at `doc/user/admin_area/settings/`. For example,
      the **Visibility and Access Controls** category should have a document
      located at `doc/user/admin_area/settings/visibility_and_access_controls.md`.
1. The `doc/topics/` directory holds topic-related technical content. Create
   `doc/topics/topic_name/subtopic_name/index.md` when subtopics become necessary.
   General user and administrator documentation should be placed accordingly.
1. The `/university/` directory is *deprecated* and the majority of its documentation
   has been moved.

If you're unsure where to place a document or a content addition, this shouldn't
stop you from authoring and contributing. Use your best judgment, and then ask
the reviewer of your MR to confirm your decision, or ask a technical writer at
any stage in the process. The technical writing team reviews all
documentation changes, regardless, and can move content if there is a better
place for it.

### Avoid duplication

Do not include the same information in multiple places.
[Link to a single source of truth instead.](#link-instead-of-summarize)

### References across documents

- Give each folder an `index.md` page that introduces the topic, and both introduces
  and links to the child pages, including to the index pages of
  any next-level sub-paths.
- To ensure discoverability, ensure each new or renamed doc is linked from its
  higher-level index page and other related pages.
- When making reference to other GitLab products and features, link to their
  respective documentation, at least on first mention.
- When making reference to third-party products or technologies, link out to
  their external sites, documentation, and resources.

### Structure within documents

- Include any and all applicable subsections as described on the
  [structure and template](../structure.md) page.
- Structure content in alphabetical order in tables, lists, and so on, unless
  there's a logical reason not to (for example, when mirroring the user
  interface or an otherwise ordered sequence).

## Language

GitLab documentation should be clear and easy to understand.

- Be clear, concise, and stick to the goal of the documentation.
- Write in US English with US grammar. (Tested in [`British.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/British.yml).)
- Use [inclusive language](#inclusive-language).

### Point of view

In most cases, it’s appropriate to use the second-person (you, yours) point of
view, because it’s friendly and easy to understand. (Tested in
[`FirstPerson.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/FirstPerson.yml).)

### Capitalization

#### Headings

Use sentence case. For example:

- `# Use variables to configure pipelines`
- `## Use the To-Do List`

#### UI text

When referring to specific user interface text, like a button label or menu
item, use the same capitalization that's displayed in the user interface.
Standards for this content are listed in the [Pajamas Design System Content section](https://design.gitlab.com/content/punctuation/)
and typically match what's called for in this Documentation Style Guide.

If you think there's a mistake in the way the user interface text is styled,
create an issue or an MR to propose a change to the user interface text.

#### Feature names

- *Feature names are typically lowercase*, like those describing actions and
  types of objects in GitLab. For example:
  - epics
  - issues
  - issue weights
  - merge requests
  - milestones
  - reorder issues
  - runner, runners, shared runners
  - a to-do item (tested in [`ToDo.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/ToDo.yml))
- *Some features are capitalized*, typically nouns naming GitLab-specific
  capabilities or tools. For example:
  - GitLab CI/CD
  - Repository Mirroring
  - Value Stream Analytics
  - the To-Do List
  - the Web IDE
  - Geo
  - GitLab Runner (see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233529) for details)

Document any exceptions in this style guide. If you're not sure, ask a GitLab
Technical Writer so that they can help decide and document the result.

Do not match the capitalization of terms or phrases on the [Features page](https://about.gitlab.com/features/)
or [features.yml](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/features.yml)
by default.

#### Other terms

Capitalize names of:

- GitLab [product tiers](https://about.gitlab.com/pricing/). For example,
  GitLab Core and GitLab Ultimate. (Tested in [`BadgeCapitalization.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/BadgeCapitalization.yml).)
- Third-party organizations, software, and products. For example, Prometheus,
  Kubernetes, Git, and The Linux Foundation.
- Methods or methodologies. For example, Continuous Integration,
  Continuous Deployment, Scrum, and Agile. (Tested in [`.markdownlint.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.markdownlint.json).)

Follow the capitalization style listed at the [authoritative source](#links-to-external-documentation)
for the entity, which may use non-standard case styles. For example: GitLab and
npm.

Use forms of *sign in*, instead of *log in* or *login*. For example:

- Sign in to GitLab.
- Open the sign-in page.

Exceptions to this rule include the concept of *single sign-on* and
references to user interface elements. For example:

- To sign in to product X, enter your credentials, and then select **Log in**.

### Inclusive language

We strive to create documentation that's inclusive. This section includes
guidance and examples for the following categories:

- [Gender-specific wording](#avoid-gender-specific-wording).
  (Tested in [`InclusionGender.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/InclusionGender.yml).)
- [Ableist language](#avoid-ableist-language).
  (Tested in [`InclusionAbleism.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/InclusionAbleism.yml).)
- [Cultural sensitivity](#culturally-sensitive-language).
  (Tested in [`InclusionCultural.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/InclusionCultural.yml).)

We write our developer documentation with inclusivity and diversity in mind. This
page is not an exhaustive reference, but describes some general guidelines and
examples that illustrate some best practices to follow.

#### Avoid gender-specific wording

When possible, use gender-neutral pronouns. For example, you can use a singular
[they](https://developers.google.com/style/pronouns#gender-neutral-pronouns) as
a gender-neutral pronoun.

Avoid the use of gender-specific pronouns, unless referring to a specific person.

<!-- vale gitlab.InclusionGender = NO -->

| Use                               | Avoid                           |
|-----------------------------------|---------------------------------|
| People, humanity                  | Mankind                         |
| GitLab Team Members               | Manpower                        |
| You can install; They can install | He can install; She can install |

<!-- vale gitlab.InclusionGender = YES -->

If you need to set up [Fake user information](#fake-user-information), use
diverse or non-gendered names with common surnames.

#### Avoid ableist language

Avoid terms that are also used in negative stereotypes for different groups.

<!-- vale gitlab.InclusionAbleism = NO -->

| Use                    | Avoid                |
|------------------------|----------------------|
| Check for completeness | Sanity check         |
| Uncertain outliers     | Crazy outliers       |
| Slows the service      | Cripples the service |
| Placeholder variable   | Dummy variable       |
| Active/Inactive        | Enabled/Disabled     |
| On/Off                 | Enabled/Disabled     |

<!-- vale gitlab.InclusionAbleism = YES -->

Credit: [Avoid ableist language](https://developers.google.com/style/inclusive-documentation#ableist-language)
in the Google Developer Style Guide.

#### Culturally sensitive language

Avoid terms that reflect negative cultural stereotypes and history. In most
cases, you can replace terms such as `master` and `slave` with terms that are
more precise and functional, such as `primary` and `secondary`.

<!-- vale gitlab.InclusionCultural = NO -->

| Use                  | Avoid                 |
|----------------------|-----------------------|
| Primary / secondary  | Master / slave        |
| Allowlist / denylist | Blacklist / whitelist |

<!-- vale gitlab.InclusionCultural = YES -->

For more information see the following [Internet Draft specification](https://tools.ietf.org/html/draft-knodel-terminology-02).

### Fake user information

You may need to include user information in entries such as a REST call or user profile.
_Do not_ use real user information or email addresses in GitLab documentation. For email
addresses and names, do use:

- _Email addresses_: Use an email address ending in `example.com`.
- _Names_: Use strings like `example_username`. Alternatively, use diverse or
  non-gendered names with common surnames, such as `Sidney Jones`, `Zhang Wei`,
  or `Alex Garcia`.

### Fake URLs

When including sample URLs in the documentation, use:

- `example.com` when the domain name is generic.
- `gitlab.example.com` when referring to self-managed instances of GitLab.

### Fake tokens

There may be times where a token is needed to demonstrate an API call using
cURL or a variable used in CI. It is strongly advised not to use real tokens in
documentation even if the probability of a token being exploited is low.

You can use the following fake tokens as examples:

| Token type            | Token value                                                        |
|:----------------------|:-------------------------------------------------------------------|
| Private user token    | `<your_access_token>`                                              |
| Personal access token | `n671WNGecHugsdEDPsyo`                                             |
| Application ID        | `2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6` |
| Application secret    | `04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df` |
| CI/CD variable        | `Li8j-mLUVA3eZYjPfd_H`                                             |
| Specific runner token | `yrnZW46BrtBFqM7xDzE7dddd`                                         |
| Shared runner token   | `6Vk7ZsosqQyfreAxXTZr`                                             |
| Trigger token         | `be20d8dcc028677c931e04f3871a9b`                                   |
| Webhook secret token  | `6XhDroRcYPM5by_h-HLY`                                             |
| Health check token    | `Tu7BgjR9qeZTEyRzGG2P`                                             |
| Request profile token | `7VgpS4Ax5utVD2esNstz`                                             |

### Language to avoid

When creating documentation, limit or avoid the use of the following verb
tenses, words, and phrases:

- Avoid jargon when possible, and when not possible, define the term or
 [link to a definition](#links-to-external-documentation).
- Avoid uncommon words when a more-common alternative is possible, ensuring that
  content is accessible to more readers.
- Don't write in the first person singular.
  (Tested in [`FirstPerson.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/FirstPerson.yml).)
  - Instead of _I_ or _me_, use _we_, _you_, _us_, or _one_.
  - When possible, stay user focused by writing in the second person (_you_ or
    the imperative).
- Don't overuse "that". In many cases, you can remove "that" from a sentence
  and improve readability.
- Avoid use of the future tense:
  - Instead of `after you execute this command, GitLab will display the result`, use
    `after you execute this command, GitLab displays the result`.
  - Only use the future tense to convey when the action or result actually
    occurs at a future time.
- Don't use slashes to clump different words together or as a replacement for
  the word "or":
  - Instead of "and/or," consider using "or," or use another sensible
    construction.
  - Other examples include "clone/fetch," author/assignee," and
    "namespace/repository name." Break apart any such instances in an
    appropriate way.
  - Exceptions to this rule include commonly accepted technical terms, such as
    CI/CD and TCP/IP.
<!-- vale gitlab.LatinTerms = NO -->
- We discourage the use of Latin abbreviations and terms, such as _e.g._,
  _i.e._, _etc._, or _via_, as even native users of English can misunderstand
  those terms. (Tested in [`LatinTerms.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/LatinTerms.yml).)
  - Instead of _i.e._, use _that is_.
  - Instead of _via_, use _through_.
  - Instead of _e.g._, use _for example_, _such as_, _for instance_, or _like_.
  - Instead of _etc._, either use _and so on_ or consider editing it out, since
    it can be vague.
<!-- vale gitlab.LatinTerms = YES -->
- Avoid using the word *currently* when talking about the product or its
  features. The documentation describes the product as it is, and not as it
  is planned to be in some indeterminate point in the future.
- Avoid using the word *scalability* when talking about increasing GitLab
  performance for additional users. The words scale or scaling are sometimes
  acceptable, but references to increasing GitLab performance for additional
  users should direct readers to the GitLab
  [reference architectures](../../../administration/reference_architectures/index.md)
  page.
- Avoid all forms of the phrases *high availability* and *HA*, and instead
  direct readers to the GitLab [reference architectures](../../../administration/reference_architectures/index.md)
  for information about configuring GitLab to have the performance needed for
  additional users over time.
- Don't use profanity or obscenities. Doing so may negatively affect other users
  and contributors, which is contrary to the GitLab value of
  [Diversity, Inclusion, and Belonging](https://about.gitlab.com/handbook/values/#diversity-inclusion).
- Avoid the use of [racially-insensitive terminology or phrases](https://www.marketplace.org/2020/06/17/tech-companies-update-language-to-avoid-offensive-terms/). For example:
  - Use *primary* and *secondary* for database and server relationships.
  - Use *allowlist* and *denylist* to describe access control lists.
- Avoid the word _please_. For details, see the [Microsoft style guide](https://docs.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/p/please).
- Avoid words like _easily_, _simply_, _handy_, and _useful._ If the user
  doesn't find the process to be these things, we lose their trust.

### Word usage clarifications

- Don't use "may" and "might" interchangeably:
  - Use "might" to indicate the probability of something occurring. "If you
    skip this step, the import process might fail."
  - Use "may" to indicate giving permission for someone to do something, or
    consider using "can" instead. "You may select either option on this
    screen." Or, "You can select either option on this screen."

### Contractions

Contractions are encouraged, and can create a friendly and informal tone,
especially in tutorials, instructional documentation, and
[user interfaces](https://design.gitlab.com/content/punctuation/#contractions).

Some contractions, however, should be avoided:

- Do not use contractions with a proper noun and a verb. For example:

  | Do                                       | Don't                                   |
  |------------------------------------------|-----------------------------------------|
  | GitLab is creating X.                    | GitLab's creating X.                    |

- Do not use contractions when you need to emphasize a negative. For example:

  | Do                                       | Don't                                   |
  |------------------------------------------|-----------------------------------------|
  | Do *not* install X with Y.               | *Don't* install X with Y.               |

- Do not use contractions in reference documentation. For example:

  | Do                                       | Don't                                   |
  |------------------------------------------|-----------------------------------------|
  | Do *not* set a limit greater than 1000.  | *Don't* set a limit greater than 1000.  |
  | For `parameter1`, the default is 10.     | For `parameter1`, the default's 10.     |

- Avoid contractions in error messages. Examples:

  | Do                                       | Don't                                   |
  |------------------------------------------|-----------------------------------------|
  | Requests to localhost are not allowed.   | Requests to localhost aren't allowed.   |
  | Specified URL cannot be used.            | Specified URL can't be used.            |

## Text

- [Write in Markdown](#markdown).
- Splitting long lines (preferably up to 100 characters) can make it easier to
  provide feedback on small chunks of text.
- Insert an empty line for new paragraphs.
- Insert an empty line between different markups (for example, after every
  paragraph, header, list, and so on). Example:

  ```markdown
  ## Header

  Paragraph.

  - List item 1
  - List item 2
  ```

### Emphasis

- Use double asterisks (`**`) to mark a word or text in bold (`**bold**`).
- Use underscore (`_`) for text in italics (`_italic_`).
- Use greater than (`>`) for blockquotes.

### Punctuation

Follow these guidelines for punctuation:

<!-- vale gitlab.Repetition = NO -->

| Rule                                                             | Example                                                |
|------------------------------------------------------------------|--------------------------------------------------------|
| Always end full sentences with a period.                         | _For a complete overview, read through this document._ |
| Always add a space after a period when beginning a new sentence. | _For a complete overview, check this doc. For other references, check out this guide._ |
| Do not use double spaces. (Tested in [`SentenceSpacing.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/SentenceSpacing.yml).) | --- |
| Do not use tabs for indentation. Use spaces instead. You can configure your code editor to output spaces instead of tabs when pressing the tab key. | --- |
| Use serial commas (_Oxford commas_) before the final _and_ or _or_ in a list of three or more items. (Tested in [`OxfordComma.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/gitlab/OxfordComma.yml).) | _You can create new issues, merge requests, and milestones._ |
| Always add a space before and after dashes when using it in a sentence (for replacing a comma, for example). | _You should try this - or not._ |
| Always use lowercase after a colon.                              | _Related Issues: a way to create a relationship between issues._ |

<!-- vale gitlab.Repetition = YES -->

### Placeholder text

You might want to provide a command or configuration that
uses specific values.

In these cases, use [`<` and `>`](https://en.wikipedia.org/wiki/Usage_message#Pattern)
to call out where a reader must replace text with their own value.

For example:

```shell
cp <your_source_directory> <your_destination_directory>
```

### Keyboard commands

Use the HTML `<kbd>` tag when referring to keystroke presses. For example:

```plaintext
To stop the command, press <kbd>Control</kbd>+<kbd>C</kbd>.
```

When the docs are generated, the output is:

To stop the command, press <kbd>Control</kbd>+<kbd>C</kbd>.

## Lists

- Always start list items with a capital letter, unless they're parameters or
  commands that are in backticks, or similar.
- Always leave a blank line before and after a list.
- Begin a line with spaces (not tabs) to denote a [nested sub-item](#nesting-inside-a-list-item).

### Ordered vs. unordered lists

Only use ordered lists when their items describe a sequence of steps to follow.

Do:

```markdown
These are the steps to do something:

1. First, do the first step.
1. Then, do the next step.
1. Finally, do the last step.
```

Don't:

```markdown
This is a list of available features:

1. Feature 1
1. Feature 2
1. Feature 3
```

### Markup

- Use dashes (`-`) for unordered lists instead of asterisks (`*`).
- Prefix `1.` to every item in an ordered list. When rendered, the list items
  display with sequential numbering.

### Punctuation

- Don't add commas (`,`) or semicolons (`;`) to the ends of list items.
- Only add periods to the end of a list item if the item consists of a complete
  sentence (with a subject and a verb).
- Be consistent throughout the list: if the majority of the items do not end in
  a period, do not end any of the items in a period, even if they consist of a
  complete sentence. The opposite is also valid: if the majority of the items
  end with a period, end all with a period.
- Separate list items from explanatory text with a colon (`:`). For example:

  ```markdown
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

Don't (vary use of periods; majority rules):

- Let's say this is a complete sentence.
- Let's say this is also a complete sentence.
- Not a complete sentence

### Nesting inside a list item

It's possible to nest items under a list item, so that they render with the same
indentation as the list item. This can be done with:

- [Code blocks](#code-blocks)
- [Blockquotes](#blockquotes)
- [Alert boxes](#alert-boxes)
- [Images](#images)

Items nested in lists should always align with the first character of the list
item. In unordered lists (using `-`), this means two spaces for each level of
indentation:

````markdown
- Unordered list item 1

  A line nested using 2 spaces to align with the `U` above.

- Unordered list item 2

  > A quote block that will nest
  > inside list item 2.

- Unordered list item 3

  ```plaintext
  a code block that nests inside list item 3
  ```

- Unordered list item 4

  ![an image that will nest inside list item 4](image.png)
````

For ordered lists, use three spaces for each level of indentation:

````markdown
1. Ordered list item 1

   A line nested using 3 spaces to align with the `O` above.

1. Ordered list item 2

   > A quote block that will nest
   > inside list item 2.

1. Ordered list item 3

   ```plaintext
   a code block that nests inside list item 3
   ```

1. Ordered list item 4

   ![an image that will nest inside list item 4](image.png)
````

You can nest full lists inside other lists using the same rules as above. If you
want to mix types, that's also possible, if you don't mix items at the same
level:

```markdown
1. Ordered list item one.
1. Ordered list item two.
   - Nested unordered list item one.
   - Nested unordered list item two.
1. Ordered list item three.

- Unordered list item one.
- Unordered list item two.
  1. Nested ordered list item one.
  1. Nested ordered list item two.
- Unordered list item three.
```

## Tables

Tables should be used to describe complex information in a straightforward
manner. Note that in many cases, an unordered list is sufficient to describe a
list of items with a single, simple description per item. But, if you have data
that's best described by a matrix, tables are the best choice.

### Creation guidelines

To keep tables accessible and scannable, tables should not have any
empty cells. If there is no otherwise meaningful value for a cell, consider entering
*N/A* (for 'not applicable') or *none*.

To help tables be easier to maintain, consider adding additional spaces to the
column widths to make them consistent. For example:

```markdown
| App name | Description          | Requirements   |
|:---------|:---------------------|:---------------|
| App 1    | Description text 1.  | Requirements 1 |
| App 2    | Description text 2.  | None           |
```

Consider installing a plugin or extension in your editor for formatting tables:

- [Markdown Table Prettifier](https://marketplace.visualstudio.com/items?itemName=darkriszty.markdown-table-prettify) for Visual Studio Code
- [Markdown Table Formatter](https://packagecontrol.io/packages/Markdown%20Table%20Formatter) for Sublime Text
- [Markdown Table Formatter](https://atom.io/packages/markdown-table-formatter) for Atom

### Feature tables

When creating tables of lists of features (such as whether or not features are
available to certain roles on the [Permissions](../../../user/permissions.md#project-members-permissions)
page), use the following phrases (based on the SVG icons):

| Option | Markdown                 | Displayed result       |
|--------|--------------------------|------------------------|
| No     | `**{dotted-circle}** No` | **{dotted-circle}** No |
| Yes    | `**{check-circle}** Yes` | **{check-circle}** Yes |

## Quotes

Valid for Markdown content only, not for front matter entries:

- Standard quotes: double quotes (`"`). Example: "This is wrapped in double
  quotes".
- Quote within a quote: double quotes (`"`) wrap single quotes (`'`). Example:
  "I am 'quoting' something within a quote".

For other punctuation rules, refer to the
[GitLab UX guide](https://design.gitlab.com/content/punctuation/).

## Headings

- Add _only one H1_ in each document, by adding `#` at the beginning of
  it (when using Markdown). The `h1` becomes the document `<title>`.
- Start with an `h2` (`##`), and respect the order `h2` > `h3` > `h4` > `h5` > `h6`.
  Never skip the hierarchy level, such as `h2` > `h4`
- Avoid putting numbers in headings. Numbers shift, hence documentation anchor
  links shift too, which eventually leads to dead links. If you think it is
  compelling to add numbers in headings, make sure to at least discuss it with
  someone in the Merge Request.
- [Avoid using symbols and special characters](https://gitlab.com/gitlab-org/gitlab-docs/-/issues/84)
  in headers. Whenever possible, they should be plain and short text.
- When possible, avoid including words that might change in the future. Changing
  a heading changes its anchor URL, which affects other linked pages.
- When introducing a new document, be careful for the headings to be
  grammatically and syntactically correct. Mention an [assigned technical writer (TW)](https://about.gitlab.com/handbook/product/product-categories/)
  for review.
  This is to ensure that no document with wrong heading is going live without an
  audit, thus preventing dead links and redirection issues when corrected.
- Leave exactly one blank line before and after a heading.
- Do not use links in headings.
- Add the corresponding [product badge](#product-tier-badges) according to the tier the
  feature belongs.
- Our documentation site search engine prioritizes words used in headings and
  subheadings. Make you subheading titles clear, descriptive, and complete to help
  users find the right example, as shown in the section on [heading titles](#heading-titles).
- See [Capitalization](#capitalization) for guidelines on capitalizing headings.

### Heading titles

Keep heading titles clear and direct. Make every word count. To accommodate
search engine optimization (SEO), use the imperative, where possible.

| Do                                    | Don't                                                       |
|:--------------------------------------|:------------------------------------------------------------|
| Configure GDK                         | Configuring GDK                                             |
| GitLab Release and Maintenance Policy | This section covers GitLab's Release and Maintenance Policy |
| Backport to older releases            | Backporting to older releases                               |
| GitLab Pages examples                 | Examples                                                    |

For guidelines on capitalizing headings, see the section on [capitalization](#capitalization).

NOTE: **Note:**
If you change an existing title, be careful. These changes might affect not
only [links](#anchor-links) within the page, but might also affect links to the
GitLab documentation from both the GitLab application and external sites.

### Anchor links

Headings generate anchor links when rendered. `## This is an example` generates
the anchor `#this-is-an-example`.

NOTE: **Note:**
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39717) in
GitLab 13.4, [product badges](#product-tier-badges) used in headings aren't
included in the generated anchor links. For example, when you link to
`## This is an example **(CORE)**`, use the anchor `#this-is-an-example`.

Keep in mind that the GitLab user interface links to many documentation pages
and anchor links to take the user to the right spot. Therefore, when you change
a heading, search `doc/*`, `app/views/*`, and `ee/app/views/*` for the old
anchor to make sure you're not breaking an anchor linked from other
documentation nor from the GitLab user interface. If you find the old anchor, be
sure to replace it with the new one.

Important:

- Avoid crosslinking documentation to headings unless you need to link to a
  specific section of the document. This avoids breaking anchors in the
  future in case the heading is changed.
- If possible, avoid changing headings since they're not only linked internally.
  There are various links to GitLab documentation on the internet, such as
  tutorials, presentations, StackOverflow posts, and other sources.
- Do not link to `h1` headings.

Note that with Kramdown, it's possible to add a custom ID to an HTML element
with Markdown markup, but they don't work in `/help`. Because of this, don't use
this option.

## Links

Links are important in GitLab documentation. They allow you to [link instead of
summarizing](#link-instead-of-summarize) to help preserve a [single source of truth](#why-a-single-source-of-truth)
within GitLab documentation.

We include guidance for links in the following categories:

- How to set up [anchor links](#anchor-links) for headings.
- How to set up [criteria](#basic-link-criteria) for configuring a link.
- What to set up when [linking to a `help`](../../documentation/index.md#linking-to-help)
  page.
- How to set up [links to internal documentation](#links-to-internal-documentation)
  for cross-references.
- How to set up [links to external documentation](#links-to-external-documentation)
  for authoritative sources.
- When to use [links requiring permissions](#links-requiring-permissions).
- How to set up a [link to a video](#link-to-video).
- How to [include links with version text](#where-to-put-version-text).
- How to [link to specific lines of code](#link-to-specific-lines-of-code)

### Basic link criteria

- Use inline link Markdown markup `[Text](https://example.com)`.
  It's easier to read, review, and maintain. _Do not_ use `[Text][identifier]`.

- Use [meaningful anchor texts](https://www.futurehosting.com/blog/links-should-have-meaningful-anchor-text-heres-why/).
  For example, instead of writing something like `Read more about GitLab Issue Boards [here](LINK)`,
  write `Read more about [GitLab Issue Boards](LINK)`.

### Links to internal documentation

NOTE: **Note:**
_Internal_ refers to documentation in the same project. When linking to
documentation in separate projects (for example, linking to Omnibus documentation
from GitLab documentation), you must use absolute URLs.

Do not use absolute URLs like `https://docs.gitlab.com/ee/index.html` to
cross-link to other documentation within the same project. Use relative links to
the file, like `../index.md`. (These are converted to HTML when the site is
rendered.)

Relative linking enables crosslinks to work:

- in Review Apps, local previews, and `/help`.
- when working on the documentation locally, so you can verify that they work as
  early as possible in the process.
- within the GitLab user interface when browsing doc files in their respective
  repositories. For example, the links displayed at
  `https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/README.md`.

To link to internal documentation:

- Use relative links to Markdown files in the same repository.
- Do not use absolute URLs or URLs from `docs.gitlab.com`.
- Use `../` to navigate to higher-level directories.
- Don't prepend `./` to links to files or directories.
- Don't link relative to root. For example, `/ee/user/gitlab_com/index.md`.

  Don't:

  - `https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html`
  - `/ee/administration/geo/replication/troubleshooting.md`
  - `./troubleshooting.md`

  Do: `../../geo/replication/troubleshooting.md`

- Always add the filename `file.md` at the end of the link with the `.md`
  extension, not `.html`.

  Don't:

  - `../../merge_requests/`
  - `../../issues/tags.html`
  - `../../issues/tags.html#stages`

  Do:

  - `../../merge_requests/index.md`
  - `../../issues/tags.md`
  - `../../issues/tags.md#stages`

NOTE: **Note:**
Using the Markdown extension is necessary for the [`/help`](../index.md#gitlab-help)
section of GitLab.

### Links to external documentation

When describing interactions with external software, it's often helpful to
include links to external documentation. When possible, make sure that you're
linking to an [**authoritative** source](#authoritative-sources). For example,
if you're describing a feature in Microsoft's Active Directory, include a link
to official Microsoft documentation.

### Authoritative sources

When citing external information, use sources that are written by the people who
created the item or product in question. These sources are the most likely to be
accurate and remain up to date.

Examples of authoritative sources include:

- Specifications, such as a [Request for Comments](https://www.ietf.org/standards/rfcs/)
  document from the Internet Engineering Task Force.
- Official documentation for a product. For example, if you're setting up an
  interface with the Google OAuth 2 authorization server, include a link to
  Google's documentation.
- Official documentation for a project. For example, if you're citing NodeJS
  functionality, refer directly to [NodeJS documentation](https://nodejs.org/en/docs/).
- Books from an authoritative publisher.

Examples of sources to avoid include:

- Personal blog posts.
- Wikipedia.
- Non-trustworthy articles.
- Discussions on forums such as Stack Overflow.
- Documentation from a company that describes another company's product.

While many of these sources to avoid can help you learn skills and or features,
they can become obsolete quickly. Nobody is obliged to maintain any of these
sites. Therefore, we should avoid using them as reference literature.

NOTE: **Note:**
Non-authoritative sources are acceptable only if there is no equivalent
authoritative source. Even then, focus on non-authoritative sources that are
extensively cited or peer-reviewed.

### Links requiring permissions

Don't link directly to:

- [Confidential issues](../../../user/project/issues/confidential_issues.md).
- Project features that require [special permissions](../../../user/permissions.md)
  to view.

These fail for:

- Those without sufficient permissions.
- Automated link checkers.

Instead:

- To reduce confusion, mention in the text that the information is either:
  - Contained in a confidential issue.
  - Requires special permission to a project to view.
- Provide a link in back ticks (`` ` ``) so that those with access to the issue
  can navigate to it.

Example:

```markdown
For more information, see the [confidential issue](../../../user/project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab-foss/-/issues/<issue_number>`.
```

### Link to specific lines of code

When linking to specific lines within a file, link to a commit instead of to the
branch. Lines of code change through time, therefore, linking to a line by using
the commit link ensures the user lands on the line you're referring to. The
**Permalink** button, which is available when viewing a file within a project,
makes it easy to generate a link to the most recent commit of the given file.

- _Do_: `[link to line 3](https://gitlab.com/gitlab-org/gitlab/-/blob/11f17c56d8b7f0b752562d78a4298a3a95b5ce66/.gitlab/issue_templates/Feature%20proposal.md#L3)`
- _Don't_: `[link to line 3](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20proposal.md#L3).`

If that linked expression is no longer in that line of the file due to additional
commits, you can still search the file for that query. In this case, update the
document to ensure it links to the most recent version of the file.

## Navigation

When documenting navigation through the user interface:

- Use the exact wording as shown in the UI, including any capital letters as-is.
- Use bold text for navigation items and the char "greater than" (`>`) as a
  separator. For example: `Navigate to your project's **Settings > CI/CD**`.
- If there are any expandable menus, make sure to mention that the user needs to
  expand the tab to find the settings you're referring to. For example:
  `Navigate to your project's **Settings > CI/CD** and expand **General pipelines**`.

### Navigational elements

Use the following terms when referring to the main GitLab user interface
elements:

- **Top menu**: This is the top menu that spans the width of the user interface.
  It includes the GitLab logo, search field, counters, and the user's avatar.
- **Left sidebar**: This is the navigation sidebar on the left of the user
  interface, specific to the project or group.
- **Right sidebar**: This is the navigation sidebar on the right of the user
  interface, specific to the open issue, merge request, or epic.

## Images

Images, including screenshots, can help a reader better understand a concept.
However, they can be hard to maintain, and should be used sparingly.

Before including an image in the documentation, ensure it provides value to the
reader.

### Capture the image

Use images to help the reader understand where they are in a process, or how
they need to interact with the application.

When you take screenshots:

- _Capture the most relevant area of the page._ Don't include unnecessary white
  space or areas of the page that don't help illustrate the point. The left
  sidebar of the GitLab user interface can change, so don't include the sidebar
  if it's not necessary.
- _Keep it small._ If you don't need to show the full width of the screen, don't.
  A value of 1000 pixels is a good maximum width for your screenshot image.
- _Be consistent._ Coordinate screenshots with the other screenshots already on
  a documentation page. For example, if other screenshots include the left
  sidebar, include the sidebar in all screenshots.

### Save the image

- Save the image with a lowercase filename that's descriptive of the feature
  or concept in the image. If the image is of the GitLab interface, append the
  GitLab version to the filename, based on the following format:
  `image_name_vX_Y.png`. For example, for a screenshot taken from the pipelines
  page of GitLab 11.1, a valid name is `pipelines_v11_1.png`. If you're adding an
  illustration that doesn't include parts of the user interface, add the release
  number corresponding to the release the image was added to; for an MR added to
  11.1's milestone, a valid name for an illustration is `devops_diagram_v11_1.png`.
- Place images in a separate directory named `img/` in the same directory where
  the `.md` document that you're working on is located.
- Consider using PNG images instead of JPEG.
- [Compress all PNG images](#compress-images).
- Compress GIFs with <https://ezgif.com/optimize> or similar tool.
- Images should be used (only when necessary) to _illustrate_ the description
  of a process, not to _replace_ it.
- Max image size: 100KB (GIFs included).
- See also how to link and embed [videos](#videos) to illustrate the
  documentation.

### Add the image link to content

The Markdown code for including an image in a document is:
`![Image description which will be the alt tag](img/document_image_title_vX_Y.png)`

The image description is the alt text for the rendered image on the
documentation site. For accessibility and SEO, use [descriptions](https://webaim.org/techniques/alttext/)
that:

- Are accurate, succinct, and unique.
- Don't use _image of…_ or _graphic of…_ to describe the image.

### Compress images

You should always compress any new images you add to the documentation. One
known tool is [`pngquant`](https://pngquant.org/), which is cross-platform and
open source. Install it by visiting the official website and following the
instructions for your OS.

GitLab has a [Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/pngquant.rake)
that you can use to automate the process. In the root directory of your local
copy of `https://gitlab.com/gitlab-org/gitlab`, run in a terminal:

- Before compressing, if you want, check that all documentation PNG images have
  been compressed:

  ```shell
  bundle exec rake pngquant:lint
  ```

- Compress all documentation PNG images using `pngquant`:

  ```shell
  bundle exec rake pngquant:compress
  ```

The only caveat is that the task runs on all images under `doc/`, not only the
ones you might have included in a merge request. In that case, you can run the
compress task and only commit the images that are relevant to your merge
request.

## Videos

Adding GitLab YouTube video tutorials to the documentation is highly
encouraged, unless the video is outdated. Videos should not replace
documentation, but complement or illustrate it. If content in a video is
fundamental to a feature and its key use cases, but this is not adequately
covered in the documentation, add this detail to the documentation text or
create an issue to review the video and do so.

Do not upload videos to the product repositories. [Link](#link-to-video) or
[embed](#embed-videos) them instead.

### Link to video

To link out to a video, include a YouTube icon so that readers can scan the page
for videos before reading:

```markdown
<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Video Title](link-to-video).
```

You can link any up-to-date video that's useful to the GitLab user.

### Embed videos

> [Introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/472) in GitLab 12.1.

The [GitLab documentation site](https://docs.gitlab.com) supports embedded
videos.

You can embed videos from [the official YouTube account for GitLab](https://www.youtube.com/channel/UCnMGQ8QHMAnVIsI3xJrihhg) only.
For videos from other sources, [link](#link-to-video) them instead.

In most cases, it is better to [link to video](#link-to-video) instead, because
an embed takes up a lot of space on the page and can be distracting to readers.

To embed a video:

1. Copy the code from this procedure and paste it into your Markdown file. Leave a
   blank line above and below it. Do _not_ edit the code (don't remove or add any spaces).
1. In YouTube, visit the video URL you want to display. Copy the regular URL
   from your browser (`https://www.youtube.com/watch?v=VIDEO-ID`) and replace
   the video title and link in the line under `<div class="video-fallback">`.
1. In YouTube, select **Share**, and then select **Embed**.
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

This is how it renders on the GitLab documentation site:

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=enMumwvLAug">What is GitLab</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/MqL6BMOySIQ" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

> Notes:
>
> - The `figure` tag is required for semantic SEO and the `video_container`
class is necessary to make sure the video is responsive and displays on
different mobile devices.
> - The `<div class="video-fallback">` is a fallback necessary for
`/help`, because the GitLab Markdown processor doesn't support iframes. It's
hidden on the documentation site, but is displayed by `/help`.

## Code blocks

- Always wrap code added to a sentence in inline code blocks (`` ` ``).
  For example, `.gitlab-ci.yml`, `git add .`, `CODEOWNERS`, or `only: [master]`.
  File names, commands, entries, and anything that refers to code should be
  added to code blocks. To make things easier for the user, always add a full
  code block for things that can be useful to copy and paste, as they can do it
  with the button on code blocks.
- HTTP methods (`HTTP POST`) and HTTP status codes, both full (`404 File Not Found`)
  and abbreviated (`404`), should be wrapped in inline code blocks when used in sentences.
  For example: Send a `DELETE` request to delete the runner. Send a `POST` request to create one.
- Add a blank line above and below code blocks.
- When providing a shell command and its output, prefix the shell command with `$`
  and leave a blank line between the command and the output.
- When providing a command without output, don't prefix the shell command with `$`.
- If you need to include triple backticks inside a code block, use four backticks
  for the code block fences instead of three.
- For regular fenced code blocks, always use a highlighting class corresponding to
  the language for better readability. Examples:

  ````markdown
  ```ruby
  Ruby code
  ```

  ```javascript
  JavaScript code
  ```

  ```markdown
  [Markdown code example](example.md)
  ```

  ```plaintext
  Code or text for which no specific highlighting class is available.
  ```
  ````

Syntax highlighting is required for fenced code blocks added to the GitLab
documentation. Refer to the following table for the most common language classes,
or check the [complete list](https://github.com/rouge-ruby/rouge/wiki/List-of-supported-languages-and-lexers)
of available language classes:

| Preferred language tags | Language aliases and notes                                                   |
|-------------------------|------------------------------------------------------------------------------|
| `asciidoc`              |                                                                              |
| `dockerfile`            | Alias: `docker`.                                                             |
| `elixir`                |                                                                              |
| `erb`                   |                                                                              |
| `golang`                | Alias: `go`.                                                                 |
| `graphql`               |                                                                              |
| `haml`                  |                                                                              |
| `html`                  |                                                                              |
| `ini`                   | For some simple configuration files that are not in TOML format.             |
| `javascript`            | Alias `js`.                                                                  |
| `json`                  |                                                                              |
| `markdown`              | Alias: `md`.                                                                 |
| `mermaid`               |                                                                              |
| `nginx`                 |                                                                              |
| `perl`                  |                                                                              |
| `php`                   |                                                                              |
| `plaintext`             | Examples with no defined language, such as output from shell commands or API calls. If a code block has no language, it defaults to `plaintext`. Alias: `text`.|
| `prometheus`            | Prometheus configuration examples.                                           |
| `python`                |                                                                              |
| `ruby`                  | Alias: `rb`.                                                                 |
| `shell`                 | Aliases: `bash` or `sh`.                                                     |
| `sql`                   |                                                                              |
| `toml`                  | Runner configuration examples, and other TOML-formatted configuration files. |
| `typescript`            | Alias: `ts`.                                                                 |
| `xml`                   |                                                                              |
| `yaml`                  | Alias: `yml`.                                                                |

For a complete reference on code blocks, see the [Kramdown guide](https://about.gitlab.com/handbook/markdown-guide/#code-blocks).

## GitLab SVG icons

> [Introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/issues/384) in GitLab 12.7.

You can use icons from the [GitLab SVG library](https://gitlab-org.gitlab.io/gitlab-svgs/)
directly in the documentation.

This way, you can achieve a consistent look when writing about interacting with
GitLab user interface elements.

Usage examples:

- Icon with default size (16px): `**{icon-name}**`

  Example: `**{tanuki}**` renders as: **{tanuki}**.
- Icon with custom size: `**{icon-name, size}**`

  Available sizes (in pixels): 8, 10, 12, 14, 16, 18, 24, 32, 48, and 72

  Example: `**{tanuki, 24}**` renders as: **{tanuki, 24}**.
- Icon with custom size and class: `**{icon-name, size, class-name}**`.

  You can access any class available to this element in GitLab documentation CSS.

  Example with `float-right`, a
  [Bootstrap utility class](https://getbootstrap.com/docs/4.4/utilities/float/):
  `**{tanuki, 32, float-right}**` renders as: **{tanuki, 32, float-right}**

### When to use icons

Icons should be used sparingly, and only in ways that aid and do not hinder the
readability of the text.

For example, the following adds little to the accompanying text:

```markdown
1. Go to **{home}** **Project overview > Details**
```

1. Go to **{home}** **Project overview > Details**

However, the following might help the reader connect the text to the user
interface:

```markdown
| Section                  | Description                                                                                                                 |
|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------|
| **{overview}** Overview  | View your GitLab Dashboard, and administer projects, users, groups, jobs, runners, and Gitaly servers.                      |
| **{monitor}** Monitoring | View GitLab system information, and information on background jobs, logs, health checks, requests profiles, and audit logs. |
| **{messages}** Messages  | Send and manage broadcast messages for your users.                                                                          |
```

| Section                  | Description                                                                                                                 |
|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------|
| **{overview}** Overview  | View your GitLab Dashboard, and administer projects, users, groups, jobs, runners, and Gitaly servers.                      |
| **{monitor}** Monitoring | View GitLab system information, and information on background jobs, logs, health checks, requests profiles, and audit logs. |
| **{messages}** Messages  | Send and manage broadcast messages for your users.                                                                          |

Use an icon when you find yourself having to describe an interface element. For
example:

- Do: Select the Admin Area icon ( **{admin}** ).
- Don't: Select the Admin Area icon (the wrench icon).

## Alert boxes

When you need to call special attention to particular sentences, use the
following markup to create highlighted alert boxes.

Alert boxes work for one paragraph only. Multiple paragraphs, lists, and headers
don't render correctly. For multiple lines, use [blockquotes](#blockquotes)
instead.

Alert boxes render only on the GitLab documentation site (<https://docs.gitlab.com>).
In the GitLab product help, alert boxes appear as plain Markdown text.

These alert boxes are used in the GitLab documentation. These aren't strict
guidelines, but for consistency you should try to use these values:

| Color  | Markup     | Default keyword | Alternative keywords                                                 |
|--------|------------|-----------------|----------------------------------------------------------------------|
| Blue   | `NOTE:`    | `**Note:**`     |                                                                      |
| Yellow | `CAUTION:` | `**Caution:**`  | `**Warning:**`, `**Important:**`                                     |
| Red    | `DANGER:`  | `**Danger:**`   | `**Warning:**`, `**Important:**`, `**Deprecated:**`, `**Required:**` |
| Green  | `TIP:`     | `**Tip:**`      |                                                                      |

### Note

Notes indicate additional information that's of special use to the reader.
Notes are most effective when used _sparingly_.

Try to avoid them. Too many notes can impact the scannability of a topic and
create an overly busy page.

Instead of adding a note, try one of these alternatives:

- Re-write the sentence as part of the most-relevant paragraph.
- Put the information into its own standalone paragraph.
- Put the content under a new subheading that introduces the topic, which makes
  it more visible.

If you must use a note, use the following formatting:

```markdown
NOTE: **Note:**
This is something to note.
```

How it renders on the GitLab documentation site:

NOTE: **Note:**
This is something to note.

### Tip

```markdown
TIP: **Tip:**
This is a tip.
```

How it renders on the GitLab documentation site:

TIP: **Tip:**
This is a tip.

### Caution

```markdown
CAUTION: **Caution:**
This is something to be cautious about.
```

How it renders on the GitLab documentation site:

CAUTION: **Caution:**
This is something to be cautious about.

### Danger

```markdown
DANGER: **Warning:**
This is a breaking change, a bug, or something very important to note.
```

How it renders on the GitLab documentation site:

DANGER: **Warning:**
This is a breaking change, a bug, or something very important to note.

## Blockquotes

For highlighting a text within a blue blockquote, use this format:

```markdown
> This is a blockquote.
```

which renders on the [GitLab documentation site](https://docs.gitlab.com) as:

> This is a blockquote.

If the text spans across multiple lines it's OK to split the line.

For multiple paragraphs, use the symbol `>` before every line:

```markdown
> This is the first paragraph.
>
> This is the second paragraph.
>
> - This is a list item
> - Second item in the list
```

Which renders to:

> This is the first paragraph.
>
> This is the second paragraph.
>
> - This is a list item
> - Second item in the list

## Terms

To maintain consistency through GitLab documentation, the following guides
documentation authors on agreed styles and usage of terms.

### Merge requests (MRs)

Merge requests allow you to exchange changes you made to source code and
collaborate with other people on the same project. This term is used in
the following ways:

- Use lowercase _merge requests_ regardless of whether referring to the feature
  or individual merge requests.

As noted in the GitLab [Writing Style Guidelines](https://about.gitlab.com/handbook/communication/#writing-style-guidelines),
if you use the _MR_ acronym, expand it at least once per document page.
Typically, the first use would be phrased as _merge request (MR)_ with subsequent
instances being _MR_.

Examples:

- "We prefer GitLab merge requests".
- "Open a merge request to fix a broken link".
- "After you open a merge request (MR), submit your MR for review and approval".

### Describe UI elements

The following are styles to follow when describing user interface elements in an
application:

- For elements with a visible label, use that label in bold with matching case.
  For example, `the **Cancel** button`.
- For elements with a tooltip or hover label, use that label in bold with
  matching case. For example, `the **Add status emoji** button`.

### Verbs for UI elements

The following are recommended verbs for specific uses with user interface
elements:

| Recommended         | Used for                              | Replaces                   |
|:--------------------|:--------------------------------------|:---------------------------|
| _select_            | buttons, links, menu items, dropdowns | "click, "press," "hit"     |
| _select_ or _clear_ | checkboxes                            | "enable", "click", "press" |
| _expand_            | expandable sections                   | "open"                     |

### Other Verbs

| Recommended | Used for                        | Replaces              |
|:------------|:--------------------------------|:----------------------|
| _go to_     | making a browser go to location | "navigate to", "open" |

## GitLab versions

To help users be aware of recent product improvements or additions, we add
GitLab version information to our documentation.

The GitLab Technical Writing team determines which versions of
documentation to display on this site based on the GitLab
[Statement of Support](https://about.gitlab.com/support/statement-of-support.html#we-support-the-current-major-version-and-the-two-previous-major-versions).

### View older GitLab documentation versions

If you're using an older version of GitLab whose version-specific information
isn't available from `docs.gitlab.com`, use one of the following methods to view a
tagged and released set of documentation for your installed version:

- In the [documentation archives](https://docs.gitlab.com/archives/).
- At the `/help` URL of your GitLab instance.
- In the documentation repository based on the respective branch (for example,
  the [13.2 branch](https://gitlab.com/gitlab-org/gitlab/-/tree/13-2-stable-ee/doc)).

### Where to put version text

When a feature is added or updated, you can include its version information
either as a **Version history** item or as an inline text reference.

Version text shouldn't include information about the tier in which the feature
is available. This information is provided by the [product badge](#product-tier-badges)
displayed for the page or feature.

#### Version text in the **Version History**

If all content in a section is related, add version text following the header
for the section. The version information must be surrounded by blank lines, and
each entry should be on its own line.

Add the version history information as a blockquote:

```markdown
## Feature name

> Introduced in GitLab 11.3.

This feature does something.
```

Whenever possible, version text should have a link to the completed issue, merge
request, or epic that introduced the feature. An issue is preferred over a merge
request, and a merge request is preferred over an epic. For example:

```markdown
> [Introduced](<link-to-issue>) in GitLab 11.3.
```

If you're adding information about new features or changes in a release, update
the blockquote to use a bulleted list:

```markdown
> - [Introduced](<link-to-issue>) in GitLab 11.3.
> - Enabled by default in GitLab 11.4.
```

If a feature is deprecated, include a link to a replacement (when available):

```markdown
> - [Deprecated](<link-to-issue>) in GitLab 11.3. Replaced by [meaningful text](<link-to-appropriate-documentation>).
```

You can also describe the replacement in surrounding text, if available. If the
deprecation isn't obvious in existing text, you may want to include a warning,
such as:

```markdown
DANGER: **Deprecated:**
This feature was [deprecated](link-to-issue) in GitLab 12.3 and replaced by
[Feature name](link-to-feature-documentation).
```

In the first major GitLab version after the feature was deprecated, be sure to
remove information about that deprecated feature.

#### Inline version text

If you're adding content to an existing topic, you can add version information
inline with the existing text.

In this case, add `([introduced/deprecated](<link-to-issue>) in GitLab X.X)`.

Including the issue link is encouraged, but isn't a requirement. For example:

```markdown
The voting strategy in GitLab 13.4 and later requires the primary and secondary
voters to agree.
```

#### End-of-life for features or products

Whenever a feature or product enters the end-of-life process, indicate its
status by using the `Danger` [alert](#alert-boxes) with the `**Important**`
keyword directly below the feature or product's header (which can include H1
page titles). Link to the deprecation and removal issues, if possible.

For example:

```markdown
DANGER: **Important:**
This feature is in its end-of-life process. It is [deprecated](link-to-issue)
for use in GitLab X.X, and is planned for [removal](link-to-issue) in GitLab X.X.
```

After the feature or product is officially deprecated and removed, remove
information about the product or feature from the GitLab documentation based on
the GitLab version where it's actually removed.

### Versions in the past or future

When describing functionality available in past or future versions, use:

- Earlier, and not older or before.
- Later, and not newer or after.

For example:

- Available in GitLab 13.1 and earlier.
- Available in GitLab 12.4 and later.
- In GitLab 12.2 and earlier, ...
- In GitLab 11.6 and later, ...

### Removing versions after each major release

Whenever a major GitLab release occurs, we remove all version references
to now-unsupported versions of GitLab. Note that this includes the removal of
specific instructions for users of non-supported GitLab versions. For example,
if we're currently supporting GitLab versions 11.x through 13.x, special
instructions for users of GitLab 10.2 and earlier to complete a task should be
removed.

To view information about the history of a feature, users can view GitLab
[release posts](https://about.gitlab.com/releases/), or search for the issue or
merge request where the work was done.

## Products and features

Refer to the information in this section when describing products and features
within the GitLab product documentation.

### Avoid line breaks in names

When entering a product or feature name that includes a space (such as
GitLab Community Edition) or even other companies' products (such as
Amazon Web Services), be sure to not split the product or feature name across
lines with an inserted line break. Splitting product or feature names across
lines makes searching for these items more difficult, and can cause problems if
names change.

For example, the following Markdown content is _not_ formatted correctly:

```markdown
When entering a product or feature name that includes a space (such as GitLab
Community Edition), don't split the product or feature name across lines.
```

Instead, it should appear similar to the following:

```markdown
When entering a product or feature name that includes a space (such as
GitLab Community Edition), don't split the product or feature name across lines.
```

### Product tier badges

When a feature is available in paid tiers, add the corresponding tier to the
header or other page element according to the feature's availability:

| Tier in which feature is available                                     | Tier markup           |
|:-----------------------------------------------------------------------|:----------------------|
| GitLab Core and GitLab.com Free, and their higher tiers                | `**(CORE)**`          |
| GitLab Starter and GitLab.com Bronze, and their higher tiers           | `**(STARTER)**`       |
| GitLab Premium and GitLab.com Silver, and their higher tiers           | `**(PREMIUM)**`       |
| GitLab Ultimate and GitLab.com Gold                                    | `**(ULTIMATE)**`      |
| _Only_ GitLab Core and higher tiers (no GitLab.com-based tiers)        | `**(CORE ONLY)**`     |
| _Only_ GitLab Starter and higher tiers (no GitLab.com-based tiers)     | `**(STARTER ONLY)**`  |
| _Only_ GitLab Premium and higher tiers (no GitLab.com-based tiers)     | `**(PREMIUM ONLY)**`  |
| _Only_ GitLab Ultimate (no GitLab.com-based tiers)                     | `**(ULTIMATE ONLY)**` |
| _Only_ GitLab.com Free and higher tiers (no self-managed instances)    | `**(FREE ONLY)**`     |
| _Only_ GitLab.com Bronze and higher tiers (no self-managed instances)  | `**(BRONZE ONLY)**`   |
| _Only_ GitLab.com Silver and higher tiers (no self-managed instances)  | `**(SILVER ONLY)**`   |
| _Only_ GitLab.com Gold (no self-managed instances)                     | `**(GOLD ONLY)**`     |

For clarity, all page title headers (H1s) must be have a tier markup for the
lowest tier that has information on the documentation page.

If sections of a page apply to higher tier levels, they can be separately
labeled with their own tier markup.

Whenever you have documentation related to the `gitlab.rb` file, you're working
with a self-managed installation. The section or page probably applies only to
self-managed instances. If so, include the relevant "`TIER` ONLY"
[product badge](#product-tier-badges) at the highest applicable heading level.

#### Product badge display behavior

When using the tier markup with headers, the documentation page displays the
full tier badge with the header line.

You can also use the tier markup with paragraphs, list items, and table cells.
For these cases, the tier mention is represented by an information icon
that displays the tiers when visitors point to the icon.
For example:

- `**(STARTER)**` displays as **(STARTER)**
- `**(STARTER ONLY)**` displays as **(STARTER ONLY)**
- `**(SILVER ONLY)**` displays as **(SILVER ONLY)**

#### How it works

Introduced by [!244](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/244),
the special markup `**(STARTER)**` generates a `span` element to trigger the
badges and tooltips (`<span class="badge-trigger starter">`). When the keyword
_only_ is added, the corresponding GitLab.com badge isn't displayed.

## Specific sections

Certain styles should be applied to specific sections. Styles for specific
sections are outlined in this section.

### GitLab restart

There are many cases that a restart/reconfigure of GitLab is required. To avoid
duplication, link to the special document that can be found in
[`doc/administration/restart_gitlab.md`](../../../administration/restart_gitlab.md).
Usually the text reads like:

```markdown
Save the file and [reconfigure GitLab](../../../administration/restart_gitlab.md)
for the changes to take effect.
```

If the document you are editing resides in a place other than the GitLab CE/EE
`doc/` directory, instead of the relative link, use the full path:
`https://docs.gitlab.com/ee/administration/restart_gitlab.html`. Replace
`reconfigure` with `restart` where appropriate.

### Installation guide

**Ruby:**
In [step 2 of the installation guide](../../../install/installation.md#2-ruby),
we install Ruby from source. When a version update is needed,
remember to change it throughout the code block and also replace
the sha256sum (it can be found in the [downloads page](https://www.ruby-lang.org/en/downloads/)
of the Ruby website).

### Configuration documentation for source and Omnibus installations

GitLab currently officially supports two installation methods: installations
from source and Omnibus packages installations.

Whenever there's a setting that's configurable for both installation methods,
the preference is to document it in the CE documentation to avoid duplication.

Configuration settings include:

- Settings that touch configuration files in `config/`.
- NGINX settings and settings in `lib/support/` in general.

When you document a list of steps, it may entail editing the configuration file
and reconfiguring or restarting GitLab. In that case, use these styles:

````markdown
**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   external_url "https://gitlab.example.com"
   ```

1. Save the file and [reconfigure](path/to/administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   GitLab for the changes to take effect.

---

**For installations from source**

1. Edit `config/gitlab.yml`:

   ```yaml
   gitlab:
     host: "gitlab.example.com"
   ```

1. Save the file and [restart](path/to/administration/restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.
````

In this case:

- Before each step list the installation method is declared in bold.
- Three dashes (`---`) are used to create a horizontal line and separate the two
  methods.
- The code blocks are indented one or more spaces under the list item to render
  correctly.
- Different highlighting languages are used for each configuration in the code block.
- The [GitLab Restart](#gitlab-restart) section is used to explain a required
  restart or reconfigure of GitLab.

### Troubleshooting

For troubleshooting sections, you should provide as much context as possible so
users can identify the problem they are facing and resolve it on their own. You
can facilitate this by making sure the troubleshooting content addresses:

1. The problem the user needs to solve.
1. How the user can confirm they have the problem.
1. Steps the user can take towards resolution of the problem.

If the contents of each category can be summarized in one line and a list of
steps aren't required, consider setting up a [table](#tables) with headers of
_Problem_ \| _Cause_ \| _Solution_ (or _Workaround_ if the fix is temporary), or
_Error message_ \| _Solution_.

## Feature flags

Learn how to [document features deployed behind flags](../feature_flags.md). For
guidance on developing GitLab with feature flags, see [Feature flags in development of GitLab](../../feature_flags/index.md).
