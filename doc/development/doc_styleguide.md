# Documentation styleguide

This styleguide recommends best practices to improve documentation and to keep
it organized and easy to find.

See also [writing documentation](writing_documentation.md).

## Location and naming of documents

>**Note:**
These guidelines derive from the discussion taken place in issue [#3349][ce-3349].

The documentation hierarchy can be vastly improved by providing a better layout
and organization of directories.

Having a structured document layout, we will be able to have meaningful URLs
like `docs.gitlab.com/user/project/merge_requests.html`. With this pattern,
you can immediately tell that you are navigating a user related documentation
and is about the project and its merge requests.

Do not create summaries of similar types of content (e.g. an index of all articles, videos, etc.),
rather organise content by its subject (e.g. everything related to CI goes together)
and cross-link between any related content.

The table below shows what kind of documentation goes where.

| Directory | What belongs here |
| --------- | -------------- |
| `doc/user/` | User related documentation. Anything that can be done within the GitLab UI goes here including `/admin`. |
| `doc/administration/`  | Documentation that requires the user to have access to the server where GitLab is installed. The admin settings that can be accessed via GitLab's interface go under `doc/user/admin_area/`. |
| `doc/api/` | API related documentation. |
| `doc/development/` | Documentation related to the development of GitLab. Any styleguides should go here. |
| `doc/legal/` | Legal documents about contributing to GitLab. |
| `doc/install/`| Probably the most visited directory, since `installation.md` is there. Ideally this should go under `doc/administration/`, but it's best to leave it as-is in order to avoid confusion (still debated though). |
| `doc/update/` | Same with `doc/install/`. Should be under `administration/`, but this is a well known location, better leave as-is, at least for now. |
| `doc/topics/` | Indexes per Topic (`doc/topics/topic-name/index.md`): all resources for that topic (user and admin documentation, articles, and third-party docs) |

---

**General rules:**

1. The correct naming and location of a new document, is a combination
   of the relative URL of the document in question and the GitLab Map design
   that is used for UX purposes ([source][graffle], [image][gitlab-map]).
1. When creating a new document and it has more than one word in its name,
   make sure to use underscores instead of spaces or dashes (`-`). For example,
   a proper naming would be `import_projects_from_github.md`. The same rule
   applies to images.
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

---

If you are unsure where a document should live, you can ping `@axil` or `@marcia` in your
merge request.

## Text

- Split up long lines, this makes it much easier to review and edit. Only
  double line breaks are shown as a full line break in [GitLab markdown][gfm].
  80-100 characters is a good line length
- Make sure that the documentation is added in the correct directory and that
  there's a link to it somewhere useful
- Do not duplicate information
- Be brief and clear
- Unless there's a logical reason not to, add documents in alphabetical order
- Write in US English
- Use [single spaces][] instead of double spaces

## Formatting

- Use dashes (`-`) for unordered lists instead of asterisks (`*`)
- Use the number one (`1`) for ordered lists
- Use underscores (`_`) to mark a word or text in italics
- Use double asterisks (`**`) to mark a word or text in bold
- When using lists, prefer not to end each item with a period. You can use
  them if there are multiple sentences, just keep the last sentence without
  a period

## Headings

- Add only one H1 title in each document, by adding `#` at the beginning of
  it (when using markdown). For subheadings, use `##`, `###` and so on
- Avoid putting numbers in headings. Numbers shift, hence documentation anchor
  links shift too, which eventually leads to dead links. If you think it is
  compelling to add numbers in headings, make sure to at least discuss it with
  someone in the Merge Request
- Avoid adding things that show ephemeral statuses. For example, if a feature is
  considered beta or experimental, put this info in a note, not in the heading.
- When introducing a new document, be careful for the headings to be
  grammatically and syntactically correct. Mention one or all
  of the following GitLab members for a review: `@axil` or `@marcia`.
  This is to ensure that no document with wrong heading is going
  live without an audit, thus preventing dead links and redirection issues when
  corrected
- Leave exactly one newline after a heading

## Links

- Use the regular inline link markdown markup `[Text](https://example.com)`.
  It's easier to read, review, and maintain.
- If there's a link that repeats several times through the same document,
  you can use `[Text][identifier]` and at the bottom of the section or the
  document add: `[identifier]: https://example.com`, in which case, we do
  encourage you to also add an alternative text: `[identifier]: https://example.com "Alternative text"` that appears when hovering your mouse on a link.

### Linking to inline docs

Sometimes it's needed to link to the built-in documentation that GitLab provides
under `/help`. This is normally done in files inside the `app/views/` directory
with the help of the `help_page_path` helper method.

In its simplest form, the HAML code to generate a link to the `/help` page is:

```haml
= link_to 'Help page', help_page_path('user/permissions')
```

The `help_page_path` contains the path to the document you want to link to with
the following conventions:

- it is relative to the `doc/` directory in the GitLab repository
- the `.md` extension must be omitted
- it must not end with a slash (`/`)

Below are some special cases where should be used depending on the context.
You can combine one or more of the following:

1. **Linking to an anchor link.** Use `anchor` as part of the `help_page_path`
   method:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions', anchor: 'anchor-link')
    ```

1. **Opening links in a new tab.** This should be the default behavior:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions'), target: '_blank'
    ```

1. **Linking to a circle icon.** Usually used in settings where a long
   description cannot be used, like near checkboxes. You can basically use
   any font awesome icon, but prefer the `question-circle`:

    ```haml
    = link_to icon('question-circle'), help_page_path('user/permissions')
    ```

1. **Using a button link.** Useful in places where text would be out of context
   with the rest of the page layout:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions'),  class: 'btn btn-info'
    ```

1. **Using links inline of some text.**

    ```haml
    Description to #{link_to 'Help page', help_page_path('user/permissions')}.
    ```

1. **Adding a period at the end of the sentence.** Useful when you don't want
   the period to be part of the link:

    ```haml
    = succeed '.' do
      Learn more in the
      = link_to 'Help page', help_page_path('user/permissions')
    ```

## Images

- Place images in a separate directory named `img/` in the same directory where
  the `.md` document that you're working on is located. Always prepend their
  names with the name of the document that they will be included in. For
  example, if there is a document called `twitter.md`, then a valid image name
  could be `twitter_login_screen.png`. [**Exception**: images for
  [articles](writing_documentation.md#technical-articles) should be
  put in a directory called `img` underneath `/articles/article_title/img/`, therefore,
  there's no need to prepend the document name to their filenames.]
- Images should have a specific, non-generic name that will differentiate them.
- Keep all file names in lower case.
- Consider using PNG images instead of JPEG.
- Compress all images with <https://tinypng.com/> or similar tool.
- Compress gifs with <https://ezgif.com/optimize> or similar tool.
- Images should be used (only when necessary) to _illustrate_ the description
of a process, not to _replace_ it.

Inside the document:

- The Markdown way of using an image inside a document is:
  `![Proper description what the image is about](img/document_image_title.png)`
- Always use a proper description for what the image is about. That way, when a
  browser fails to show the image, this text will be used as an alternative
  description
- If there are consecutive images with little text between them, always add
  three dashes (`---`) between the image and the text to create a horizontal
  line for better clarity
- If a heading is placed right after an image, always add three dashes (`---`)
  between the image and the heading

## Notes

- Notes should be quoted with the word `Note:` being bold. Use this form:

    ```
    >**Note:**
    This is something to note.
    ```

    which renders to:

    >**Note:**
    This is something to note.

    If the note spans across multiple lines it's OK to split the line.

## New features

New features must be shipped with its accompanying documentation and the doc
reviewed by a technical writer.

### Mentioning GitLab versions and tiers

- Every piece of documentation that comes with a new feature should declare the
  GitLab version that feature got introduced. Right below the heading add a
  note:

    ```
    > Introduced in GitLab 8.3.
    ```

- If possible every feature should have a link to the MR, issue, or epic that introduced it.
  The above note would be then transformed to:

    ```
    > [Introduced][ce-1242] in GitLab 8.3.
    ```

    , where the [link identifier](#links) is named after the repository (CE) and
    the MR number.

- If the feature is only available in GitLab Enterprise Edition, don't forget to mention
  the [paid tier](https://about.gitlab.com/handbook/marketing/product-marketing/#tiers)
  the feature is available in:

    ```
    > [Introduced][ee-1234] in [GitLab Starter](https://about.gitlab.com/products/) 8.3.
    ```

    Otherwise, leave this mention out.

## References

- **GitLab Restart:**
  There are many cases that a restart/reconfigure of GitLab is required. To
  avoid duplication, link to the special document that can be found in
  [`doc/administration/restart_gitlab.md`][doc-restart]. Usually the text will
  read like:

    ```
    Save the file and [reconfigure GitLab](../administration/restart_gitlab.md)
    for the changes to take effect.
    ```
  If the document you are editing resides in a place other than the GitLab CE/EE
  `doc/` directory, instead of the relative link, use the full path:
  `http://docs.gitlab.com/ce/administration/restart_gitlab.html`.
  Replace `reconfigure` with `restart` where appropriate.

## Installation guide

- **Ruby:**
  In [step 2 of the installation guide](../install/installation.md#2-ruby),
  we install Ruby from source. Whenever there is a new version that needs to
  be updated, remember to change it throughout the codeblock and also replace
  the sha256sum (it can be found in the [downloads page][ruby-dl] of the Ruby
  website).

[ruby-dl]: https://www.ruby-lang.org/en/downloads/ "Ruby download website"

## Changing document location

Changing a document's location is not to be taken lightly. Remember that the
documentation is available to all installations under `help/` and not only to
GitLab.com or http://docs.gitlab.com. Make sure this is discussed with the
Documentation team beforehand.

If you indeed need to change a document's location, do NOT remove the old
document, but rather replace all of its contents with a new line:

```
This document was moved to [another location](path/to/new_doc.md).
```

where `path/to/new_doc.md` is the relative path to the root directory `doc/`.

---

For example, if you were to move `doc/workflow/lfs/lfs_administration.md` to
`doc/administration/lfs.md`, then the steps would be:

1. Copy `doc/workflow/lfs/lfs_administration.md` to `doc/administration/lfs.md`
1. Replace the contents of `doc/workflow/lfs/lfs_administration.md` with:

    ```
    This document was moved to [another location](../../administration/lfs.md).
    ```

1. Find and replace any occurrences of the old location with the new one.
   A quick way to find them is to use `git grep`. First go to the root directory
   where you cloned the `gitlab-ce` repository and then do:

    ```
    git grep -n "workflow/lfs/lfs_administration"
    git grep -n "lfs/lfs_administration"
    ```

NOTE: **Note:**
If the document being moved has any Disqus comments on it, there are extra steps
to follow documented just [below](#redirections-for-pages-with-disqus-comments).

Things to note:

- Since we also use inline documentation, except for the documentation itself,
  the document might also be referenced in the views of GitLab (`app/`) which will
  render when visiting `/help`, and sometimes in the testing suite (`spec/`).
- The above `git grep` command will search recursively in the directory you run
  it in for `workflow/lfs/lfs_administration` and `lfs/lfs_administration`
  and will print the file and the line where this file is mentioned.
  You may ask why the two greps. Since we use relative paths to link to
  documentation, sometimes it might be useful to search a path deeper.
- The `*.md` extension is not used when a document is linked to GitLab's
  built-in help page, that's why we omit it in `git grep`.
- Use the checklist on the documentation MR description template.

### Redirections for pages with Disqus comments

If the documentation page being relocated already has any Disqus comments,
we need to preserve the Disqus thread.

Disqus uses an identifier per page, and for docs.gitlab.com, the page identifier
is configured to be the page URL. Therefore, when we change the document location,
we need to preserve the old URL as the same Disqus identifier.

To do that, add to the frontmatter the variable `redirect_from`,
using the old URL as value. For example, let's say I moved the document
available under `https://docs.gitlab.com/my-old-location/README.html` to a new location,
`https://docs.gitlab.com/my-new-location/index.html`.

Into the **new document** frontmatter add the following:

```yaml
---
redirect_from: 'https://docs.gitlab.com/my-old-location/README.html'
---
```

Note: it is necessary to include the file name in the `redirect_from` URL,
even if it's `index.html` or `README.html`.

## Configuration documentation for source and Omnibus installations

GitLab currently officially supports two installation methods: installations
from source and Omnibus packages installations.

Whenever there is a setting that is configurable for both installation methods,
prefer to document it in the CE docs to avoid duplication.

Configuration settings include:

- settings that touch configuration files in `config/`
- NGINX settings and settings in `lib/support/` in general

When there is a list of steps to perform, usually that entails editing the
configuration file and reconfiguring/restarting GitLab. In such case, follow
the style below as a guide:

````
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
````

In this case:

- before each step list the installation method is declared in bold
- three dashes (`---`) are used to create a horizontal line and separate the
  two methods
- the code blocks are indented one or more spaces under the list item to render
  correctly
- different highlighting languages are used for each config in the code block
- the [references](#references) guide is used for reconfigure/restart

## Fake tokens

There may be times where a token is needed to demonstrate an API call using
cURL or a secret variable used in CI. It is strongly advised not to use real
tokens in documentation even if the probability of a token being exploited is
low.

You can use the following fake tokens as examples.

|     **Token type**    |           **Token value**         |
| --------------------- | --------------------------------- |
| Private user token    | `9koXpg98eAheJpvBs5tK`            |
| Personal access token | `n671WNGecHugsdEDPsyo`            |
| Application ID        | `2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6` |
| Application secret    | `04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df` |
| Secret CI variable    | `Li8j-mLUVA3eZYjPfd_H`            |
| Specific Runner token | `yrnZW46BrtBFqM7xDzE7dddd`        |
| Shared Runner token   | `6Vk7ZsosqQyfreAxXTZr`            |
| Trigger token         | `be20d8dcc028677c931e04f3871a9b`  |
| Webhook secret token  | `6XhDroRcYPM5by_h-HLY`            |
| Health check token    | `Tu7BgjR9qeZTEyRzGG2P`            |
| Request profile token | `7VgpS4Ax5utVD2esNstz`            |

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

### Method description

Use the following table headers to describe the methods. Attributes should
always be in code blocks using backticks (`).

```
| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
```

Rendered example:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user`  | string | yes | The GitLab username |

### cURL commands

- Use `https://gitlab.example.com/api/v4/` as an endpoint.
- Wherever needed use this personal access token: `9koXpg98eAheJpvBs5tK`.
- Always put the request first. `GET` is the default so you don't have to
  include it.
- Use double quotes to the URL when it includes additional parameters.
- Prefer to use examples using the personal access token and don't pass data of
  username and password.

| Methods | Description |
| ------- | ----------- |
| `-H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK"` | Use this method as is, whenever authentication needed |
| `-X POST`   | Use this method when creating new objects |
| `-X PUT`    | Use this method when updating existing objects |
| `-X DELETE` | Use this method when removing existing objects |

### cURL Examples

Below is a set of [cURL][] examples that you can use in the API documentation.

#### Simple cURL command

Get the details of a group:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/gitlab-org
```

#### cURL example with parameters passed in the URL

Create a new project under the authenticated user's namespace:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects?name=foo"
```

#### Post data using cURL's --data

Instead of using `-X POST` and appending the parameters to the URI, you can use
cURL's `--data` option. The example below will create a new project `foo` under
the authenticated user's namespace.

```bash
curl --data "name=foo" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects"
```

#### Post data using JSON content

> **Note:** In this example we create a new group. Watch carefully the single
and double quotes.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"path": "my-group", "name": "My group"}' https://gitlab.example.com/api/v4/groups
```

#### Post data using form-data

Instead of using JSON or urlencode you can use multipart/form-data which
properly handles data encoding:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "title=ssh-key" --form "key=ssh-rsa AAAAB3NzaC1yc2EA..." https://gitlab.example.com/api/v4/users/25/keys
```

The above example is run by and administrator and will add an SSH public key
titled ssh-key to user's account which has an id of 25.

#### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Observe how spaces are escaped using the `%20`
ASCII code.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

#### Pass arrays to API calls

The GitLab API sometimes accepts arrays of strings or integers. For example, to
restrict the sign-up e-mail domains of a GitLab instance to `*.example.com` and
`example.net`, you would do something like this:

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "domain_whitelist[]=*.example.com" --data "domain_whitelist[]=example.net" https://gitlab.example.com/api/v4/application/settings
```

[cURL]: http://curl.haxx.se/ "cURL website"
[single spaces]: http://www.slate.com/articles/technology/technology/2011/01/space_invaders.html
[gfm]: http://docs.gitlab.com/ce/user/markdown.html#newlines "GitLab flavored markdown documentation"
[ce-1242]: https://gitlab.com/gitlab-org/gitlab-ce/issues/1242
[doc-restart]: ../administration/restart_gitlab.md "GitLab restart documentation"
[ce-3349]: https://gitlab.com/gitlab-org/gitlab-ce/issues/3349 "Documentation restructure"
[graffle]: https://gitlab.com/gitlab-org/gitlab-design/blob/d8d39f4a87b90fb9ae89ca12dc565347b4900d5e/production/resources/gitlab-map.graffle
[gitlab-map]: https://gitlab.com/gitlab-org/gitlab-design/raw/master/production/resources/gitlab-map.png
