# Documentation style guidelines

The documentation style guide defines the markup structure used in
GitLab documentation. Check the
[documentation guidelines](writing_documentation.md) for general development instructions.

Check the GitLab hanbook for the [writing styles guidelines](https://about.gitlab.com/handbook/communication/#writing-style-guidelines).

## Text

- Split up long lines (wrap text), this makes it much easier to review and edit. Only
  double line breaks are shown as a full line break in [GitLab markdown][gfm].
  80-100 characters is a good line length
- Make sure that the documentation is added in the correct
  [directory](writing_documentation.md#documentation-directory-structure) and that
  there's a link to it somewhere useful
- Do not duplicate information
- Be brief and clear
- Unless there's a logical reason not to, add documents in alphabetical order
- Write in US English
- Use [single spaces][] instead of double spaces
- Jump a line between different markups (e.g., after every paragraph, hearder, list, etc)
- Capitalize "G" and "L" in GitLab
- Capitalize feature, products, and methods names. E.g.: GitLab Runner, Geo,
Issue Boards, Git, Prometheus, Continuous Integration.

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
- [Avoid using symbols and special chars](https://gitlab.com/gitlab-com/gitlab-docs/issues/84)
  in headers. Whenever possible, they should be plain and short text.
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
- To link to internal documentation, use relative links, not full URLs. Use `../` to
  navigate tp high-level directories, and always add the file name `file.md` at the
  end of the link with the `.md` extension, not `.html`.
  Example: instead of `[text](../../merge_requests/)`, use
  `[text](../../merge_requests/index.md)` or, `[text](../../ci/README.md)`, or,
  for anchor links, `[text](../../ci/README.md#examples)`.
  Using the markdown extension is necessary for the [`/help`](writing_documentation.md#gitlab-help)
  section of GitLab.
- To link from CE to EE-only documentation, use the EE-only doc full URL.
- Use [meaningful anchor texts](https://www.futurehosting.com/blog/links-should-have-meaningful-anchor-text-heres-why/).
  E.g., instead of writing something like `Read more about GitLab Issue Boards [here](LINK)`,
  write `Read more about [GitLab Issue Boards](LINK)`.

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

    ```md
    >**Note:**
    This is something to note.
    ```

    which renders to:

    >**Note:**
    This is something to note.

    If the note spans across multiple lines it's OK to split the line.

## Specific sections and terms

To mention and/or reference specific terms in GitLab, please follow the styles
below.

### GitLab versions and tiers

- Every piece of documentation that comes with a new feature should declare the
  GitLab version that feature got introduced. Right below the heading add a
  note:

    ```md
    > Introduced in GitLab 8.3.
    ```

- If possible every feature should have a link to the MR, issue, or epic that introduced it.
  The above note would be then transformed to:

    ```md
    > [Introduced][ce-1242] in GitLab 8.3.
    ```

    , where the [link identifier](#links) is named after the repository (CE) and
    the MR number.

- If the feature is only available in GitLab Enterprise Edition, don't forget to mention
  the [paid tier](https://about.gitlab.com/handbook/marketing/product-marketing/#tiers)
  the feature is available in:

    ```md
    > [Introduced][ee-1234] in [GitLab Starter](https://about.gitlab.com/products/) 8.3.
    ```

    Otherwise, leave this mention out.

### Product badges

When a feature is available in EE-only tiers, add the corresponding tier according to the
feature availability:

- For GitLab Starter and GitLab.com Bronze: `** [STARTER] **`
- For GitLab Premium and GitLab.com Silver: `** [PREMIUM] **`
- For GitLab Ultimate and GitLab.com Gold: `** [ULTIMATE] **`
- For GitLab Core and GitLab.com Free: `** [CORE] **`

To exclude GitLab.com tiers (when the feature is not available in GitLab.com), add the
keyword "only":

- For GitLab Starter: `** [STARTER ONLY] **`
- For GitLab Premium: `** [PREMIUM ONLY] **`
- For GitLab Ultimate: `** [ULTIMATE ONLY] **`
- For GitLab Core: `** [CORE ONLY] **`

The tier should be ideally added to headers, so that the full badge will be displayed.
But it can be also mentioned from paragraphs, list items, and table cells. For these cases,
the tier mention will be represented by an orange question mark.
E.g. `** [STARTER] **` renders **[STARTER]**.

The absence of tiers' mentions mean that the feature is available in GitLab Core,
GitLab.com Free, and higher tiers.

Note that spaces between `*` and `[]` were added for escaping the special markup.

#### How it works

Introduced by [!244](https://gitlab.com/gitlab-com/gitlab-docs/merge_requests/244),
the special markup `** [STARTER] **` will generate a `span` element to trigger the
badges and tooltips (`**[STARTER]**`). When the keyword "only" is added, the
corresponding GitLab.com badge will not be displayed.

### GitLab Restart

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

### Installation guide

**Ruby:**
In [step 2 of the installation guide](../install/installation.md#2-ruby),
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

- settings that touch configuration files in `config/`
- NGINX settings and settings in `lib/support/` in general

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

- before each step list the installation method is declared in bold
- three dashes (`---`) are used to create a horizontal line and separate the
  two methods
- the code blocks are indented one or more spaces under the list item to render
  correctly
- different highlighting languages are used for each config in the code block
- the [references](#references) guide is used for reconfigure/restart

### Fake tokens

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

### API

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

#### Method description

Use the following table headers to describe the methods. Attributes should
always be in code blocks using backticks (``` ` ```).

```
| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
```

Rendered example:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user`  | string | yes | The GitLab username |

#### cURL commands

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

#### cURL Examples

Below is a set of [cURL][] examples that you can use in the API documentation.

##### Simple cURL command

Get the details of a group:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/gitlab-org
```

##### cURL example with parameters passed in the URL

Create a new project under the authenticated user's namespace:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects?name=foo"
```

##### Post data using cURL's --data

Instead of using `-X POST` and appending the parameters to the URI, you can use
cURL's `--data` option. The example below will create a new project `foo` under
the authenticated user's namespace.

```bash
curl --data "name=foo" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects"
```

##### Post data using JSON content

> **Note:** In this example we create a new group. Watch carefully the single
and double quotes.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"path": "my-group", "name": "My group"}' https://gitlab.example.com/api/v4/groups
```

##### Post data using form-data

Instead of using JSON or urlencode you can use multipart/form-data which
properly handles data encoding:

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "title=ssh-key" --form "key=ssh-rsa AAAAB3NzaC1yc2EA..." https://gitlab.example.com/api/v4/users/25/keys
```

The above example is run by and administrator and will add an SSH public key
titled ssh-key to user's account which has an id of 25.

##### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Observe how spaces are escaped using the `%20`
ASCII code.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

##### Pass arrays to API calls

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
