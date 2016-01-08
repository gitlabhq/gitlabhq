# Documentation styleguide

This styleguide recommends best practices to improve documentation and to keep it organized and easy to find.

## Text

- Split up long lines, this makes it much easier to review and edit. Only
  double line breaks are shown as a full line break in markdown. 80 characters
  is a good line length.
- For subtitles, make sure to start with the largest and go down, meaning:
  `#` for the title, `##` for subtitles and `###` for subtitles of the subtitles, etc.
- Make sure that the documentation is added in the correct directory and that
  there's a link to it somewhere useful.
- Add only one H1 or title in each document, by adding '#' at the begining of
  it (when using markdown). For subtitles, use '##', '###' and so on.
- Do not duplicate information.
- Be brief and clear.
- Whenever it applies, add documents in alphabetical order.
- Write in US English
- Use [single spaces](http://www.slate.com/articles/technology/technology/2011/01/space_invaders.html) instead of double spaces.

## Images

- Create a directory to store the images with the specific name of the document
  where the images belong. It could be in the same directory where the `.md`
  document that you're working on is located.
- Images should have a specific, non-generic name that will differentiate them.
- Keep all file names in lower case.

## API

Here is a list of must have items. Further explanation is given below.

- Every method must have the REST request. For example:

    ```
    GET /projects/:id/repository/branches
    ```

- Every method must have a cURL example.
- Every method must have a response body (in json format).

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
- Use double quotes to the url when it includes additional parameters.
- Prefer to use examples using the private token and don't pass data of username
  and password.

| Methods | Description |
| ------- | ----------- |
| `-H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK"` | Use this method as is, whenever authentication needed |
| `-X POST`   | Use this method when creating new objects |
| `-X PUT`    | Use this method when updating existing objects |
| `-X DELETE` | Use this method when removing existing objects |

### cURL Examples

Below is a set of [cURL][] commands that should be used in the API
documentation.

#### Get the details of a group

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/gitlab-org
```

#### Create a new project under the authenticated user's namespace

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects?name=foo"
```

#### Post data using json content

**Note:** In this example we create a new group. Watch carefully the single and
double quotes.

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" -H "Content-Type: application/json" --data '{"path": "my-group", "name": "My group"}' https://gitlab.example.com/api/v3/groups
```

#### Post data using curl's --data

Instead of using `-X POST` and appending the parameters to the URI, you can use
curl's `--data` option. The example below will create a new project `foo` under
the authenticated user's namespace.

```bash
curl --data "name=foo" -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects"
```

#### Post data using form-data

Instead of using json or urlencode you can use mutlipart/form-data which
properly handles data encoding:

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" -F "title=ssh-key" -F "key=ssh-rsa AAAAB3NzaC1yc2EA..." https://gitlab.example.com/api/v3/users/25/keys
```

The above example is run by and administrator and will add an SSH public key
titled ssh-key to user's account which has an id of 25.

#### Escape special characters

Spaces or slashes (`/`) may sometimes result to errors, thus it is recommended
to escape them when possible. In the example below we create a new issue which
contains spaces in its title. Watch how spaces are escaped using the `%20`
ASCII code.

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/42/issues?title=Hello%20Dude"
```

Use `%2F` for slashes (`/`).

#### Pass arrays to API calls

The GitLab API sometimes accepts arrays of strings or integers. For example, to
restrict the sign-up e-mail domains of a GitLab instance to `*.example.com` and
`example.net`, you would do something like this:

```bash
curl -X PUT -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" -d "restricted_signup_domains[]=*.example.com" -d "restricted_signup_domains[]=example.net" https://gitlab.example.com/api/v3/application/settings
```
