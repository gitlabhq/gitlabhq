---
source_checksum: 5278bc6b07a981fb
distilled_at_sha: 98353ccc8444ff6f7b594c7118283ddc21bb19d5
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Documentation API Principles

## Checklist

### REST API — Page Setup

- After adding a new API documentation page, add an entry in the global navigation (`api_resources.md` and the global nav).
- Set the `description` front matter to start with "REST API to", use action verbs, avoid words ending in -ing, keep it under 100 characters, and end with a period.
- Include a block with the HTTP method and request path (always starting with `/`) at the top of each operation topic.
- Include a detailed description of request attributes, a detailed description of response attributes, a cURL example, and a JSON response body example for every operation.

### REST API — OpenAPI Definition

- Run `bin/rake gitlab:openapi:v2:generate` and `bin/rake gitlab:openapi:v3:generate` when modifying API Markdown or code to update the OpenAPI definition (checked by the `openapi-doc-check` CI/CD job).
- Verify the OpenAPI definition is up to date by running `bin/rake gitlab:openapi:v2:check_docs` and `bin/rake gitlab:openapi:v3:check_docs` before merging.

### REST API — History and Deprecations

- Add history notes to describe new or updated API calls; include feature flag information in history when the API or attribute is behind a feature flag.
- To deprecate an attribute: add a history note, add inline deprecation text to the attribute's table row (e.g. `[Deprecated](link) in GitLab 14.7. Use \`widget_id\` instead.`), and update the REST API deprecations page for wide announcement.

### REST API — Operation Titles and Descriptions

- Start operation titles with a verb: use `List all` for `GET` (multiple), `Retrieve` or `Download` for `GET` (single), `Create` or `Add` for `POST`, `Update` or `Replace` for `PUT`, `Update` or `Modify` for `PATCH`, and `Delete` for `DELETE`.
- Write the first sentence of an operation description to broadly repeat the title (e.g. `List all project access tokens.`).
- Start the API introduction with `Use this API to {verb} + [{feature}](link)` and link to related UI documentation.

### REST API — Request Attributes

- List path attributes first, then required attributes, then sort remaining attributes alphabetically in request attribute tables.
- Place attribute names in backtick code blocks in all attribute tables.
- Document tier and offering restrictions (e.g. `GitLab Self-Managed, Premium and Ultimate only.`) in the attribute description; combine tier and offering information when possible.
- For conditionally required attributes, use the format `Required if \`attribute1\` is \`true\`.` in the description and set the Required column to `Conditional`.

### REST API — Response Attributes

- Sort response attribute tables alphabetically.
- Use dot notation for sub-attributes of objects or arrays (e.g. `project.name` or `projects[].name`).
- Start the response description with `If successful, returns [\`<status_code>\`](rest/troubleshooting.md#status-codes) and the following response attributes:`.

### REST API — cURL Examples

- Always put `--request <METHOD>` first in cURL commands, including for `GET`.
- Use long option names (`--header` instead of `-H`, `--url` instead of `-u`) in all cURL examples (linted by `scripts/lint-doc.sh`).
- Declare URLs with `--url` and wrap the URL in double quotes.
- Use `https://gitlab.example.com/api/v4/` as the endpoint and `<your_access_token>` as the personal access token placeholder.
- Use `--data-urlencode` for data containing special characters (Markdown, regex, quotes, ampersands); use `--data` for plain alphanumeric data.
- DO NOT use real user information, real URLs, or real tokens in cURL examples.
- Use `%20` for spaces and `%2F` for slashes when escaping special characters in URLs.
- Pass arrays by repeating the parameter with `[]` suffix (e.g. `--data "skip_users[]=<id>"`).

### GraphQL — Example Pages

- Create dedicated GraphQL example pages as `.md` files in `doc/api/graphql/` with a functional name (e.g. `import_from_specific_location.md`).
- Include front matter with `stage`, `group`, `info`, and `title`; add a `details` shortcode block listing tier and offering.
- After merging the main MR, open a second MR against the `docs-gitlab-com` repository to add the new page to the global navigation under the `GraphQL` section in `navigation.yaml`; DO NOT merge the nav MR before the content MR is live on `docs.gitlab.com`.

## Authoritative sources

For the full picture, see:

- doc/development/documentation/restful_api_styleguide.md
- doc/development/documentation/graphql_styleguide.md

