# Documentation styleguide

This styleguide recommends best practices to improve documentation and to keep
it organized and easy to find.

## Location and naming of documents

>**Note:**
These guidelines derive from the discussion taken place in issue [#3349][ce-3349].

The documentation hierarchy can be vastly improved by providing a better layout
and organization of directories.

Having a structured document layout, we will be able to have meaningful URLs
like `docs.gitlab.com/user/project/merge_requests.html`. With this pattern,
you can immediately tell that you are navigating a user related documentation
and is about the project and its merge requests.

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

---

If you are unsure where a document should live, you can ping `@axil` in your
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
- When introducing a new document, be careful for the headings to be
  grammatically and syntactically correct. It is advised to mention one or all
  of the following GitLab members for a review: `@axil`, `@rspeicher`,
  `@dblessing`, `@ashleys`. This is to ensure that no document
  with wrong heading is going live without an audit, thus preventing dead links
  and redirection issues when corrected
- Leave exactly one newline after a heading

## Links

- If a link makes the paragraph to span across multiple lines, do not use
  the regular Markdown approach: `[Text](https://example.com)`. Instead use
  `[Text][identifier]` and at the very bottom of the document add:
  `[identifier]: https://example.com`. This is another way to create Markdown
  links which keeps the document clear and concise. Bonus points if you also
  add an alternative text: `[identifier]: https://example.com "Alternative text"`
  that appears when hovering your mouse on a link

## Images

- Place images in a separate directory named `img/` in the same directory where
  the `.md` document that you're working on is located. Always prepend their
  names with the name of the document that they will be included in. For
  example, if there is a document called `twitter.md`, then a valid image name
  could be `twitter_login_screen.png`.
- Images should have a specific, non-generic name that will differentiate them.
- Keep all file names in lower case.
- Consider using PNG images instead of JPEG.

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

- Every piece of documentation that comes with a new feature should declare the
  GitLab version that feature got introduced. Right below the heading add a
  note:

    ```
    > Introduced in GitLab 8.3.
    ```

- If possible every feature should have a link to the MR that introduced it.
  The above note would be then transformed to:

    ```
    > [Introduced][ce-1242] in GitLab 8.3.
    ```

    , where the [link identifier](#links) is named after the repository (CE) and
    the MR number.

- If the feature is only in GitLab Enterprise Edition, don't forget to mention
  it, like:

    ```
    > Introduced in GitLab Enterprise Edition 8.3.
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
document, but rather put a text in it that points to the new location, like:

```
This document was moved to [path/to/new_doc.md](path/to/new_doc.md).
```

where `path/to/new_doc.md` is the relative path to the root directory `doc/`.

---

For example, if you were to move `doc/workflow/lfs/lfs_administration.md` to
`doc/administration/lfs.md`, then the steps would be:

1. Copy `doc/workflow/lfs/lfs_administration.md` to `doc/administration/lfs.md`
1. Replace the contents of `doc/workflow/lfs/lfs_administration.md` with:

    ```
    This document was moved to [administration/lfs.md](../../administration/lfs.md).
    ```

1. Find and replace any occurrences of the old location with the new one.
   A quick way to find them is to use `git grep`. First go to the root directory
   where you cloned the `gitlab-ce` repository and then do:

    ```
    git grep -n "workflow/lfs/lfs_administration"
    git grep -n "lfs/lfs_administration"
    ```

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


[reconfigure]: path/to/administration/gitlab_restart.md#omnibus-gitlab-reconfigure
[restart]: path/to/administration/gitlab_restart.md#installations-from-source
````

In this case:

- before each step list the installation method is declared in bold
- three dashes (`---`) are used to create an horizontal line and separate the
  two methods
- the code blocks are indented one or more spaces under the list item to render
  correctly
- different highlighting languages are used for each config in the code block
- the [references](#references) guide is used for reconfigure/restart

## API

Here is a list of must-have items. Use them in the exact order that appears
on this document. Further explanation is given below.

- Every method must be described using [Grape's DSL](https://github.com/ruby-grape/grape/tree/v0.13.0#describing-methods)
  (see https://gitlab.com/gitlab-org/gitlab-ce/blob/master/lib/api/environments.rb
  for a good example):
  - `desc` for the method summary (you can pass it a block for additional details)
  - `params` for the method params (this acts as description **and** validation
    of the params)
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

- Use `https://gitlab.example.com/api/v3/` as an endpoint.
- Wherever needed use this private token: `9koXpg98eAheJpvBs5tK`.
- Always put the request first. `GET` is the default so you don't have to
  include it.
- Use double quotes to the URL when it includes additional parameters.
- Prefer to use examples using the private token and don't pass data of
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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/gitlab-org
```

#### cURL example with parameters passed in the URL

Create a new project under the authenticated user's namespace:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects?name=foo"
```

#### Post data using cURL's --data

Instead of using `-X POST` and appending the parameters to the URI, you can use
cURL's `--data` option. The example below will create a new project `foo` under
the authenticated user's namespace.

```bash
curl --data "name=foo" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects"
```

#### Post data using JSON content

> **Note:** In this example we create a new group. Watch carefully the single
and double quotes.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"path": "my-group", "name": "My group"}' https://gitlab.example.com/api/v3/groups
```

#### Post data using form-data

Instead of using JSON or urlencode you can use multipart/form-data which
properly handles data encoding:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "title=ssh-key" --form "key=ssh-rsa AAAAB3NzaC1yc2EA..." https://gitlab.example.com/api/v3/users/25/keys
```

The above example is run by and administrator and will add an SSH public key
titled ssh-key to user's account which has an id of 25.

#### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Observe how spaces are escaped using the `%20`
ASCII code.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

#### Pass arrays to API calls

The GitLab API sometimes accepts arrays of strings or integers. For example, to
restrict the sign-up e-mail domains of a GitLab instance to `*.example.com` and
`example.net`, you would do something like this:

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "domain_whitelist[]=*.example.com" --data "domain_whitelist[]=example.net" https://gitlab.example.com/api/v3/application/settings
```

[cURL]: http://curl.haxx.se/ "cURL website"
[single spaces]: http://www.slate.com/articles/technology/technology/2011/01/space_invaders.html
[gfm]: http://docs.gitlab.com/ce/user/markdown.html#newlines "GitLab flavored markdown documentation"
[doc-restart]: ../administration/restart_gitlab.md "GitLab restart documentation"
[ce-3349]: https://gitlab.com/gitlab-org/gitlab-ce/issues/3349 "Documentation restructure"
[graffle]: https://gitlab.com/gitlab-org/gitlab-design/blob/d8d39f4a87b90fb9ae89ca12dc565347b4900d5e/production/resources/gitlab-map.graffle
[gitlab-map]: https://gitlab.com/gitlab-org/gitlab-design/raw/master/production/resources/gitlab-map.png
