---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Dockerfiles API

GitLab provides an API endpoint for instance-level Dockerfile templates.
Default templates are defined at
[`vendor/Dockerfile`](https://gitlab.com/gitlab-org/gitlab-foss/-/tree/master/vendor/Dockerfile)
in the GitLab repository.

## Override Dockerfile API templates **(PREMIUM SELF)**

In [GitLab Premium and higher](https://about.gitlab.com/pricing/) tiers, GitLab instance
administrators can override templates in the
[Admin Area](../../user/admin_area/settings/instance_template_repository.md).

## List Dockerfile templates

Get all Dockerfile templates.

```plaintext
GET /templates/dockerfiles
```

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles"
```

Example response:

```json
[
  {
    "key": "Binary",
    "name": "Binary"
  },
  {
    "key": "Binary-alpine",
    "name": "Binary-alpine"
  },
  {
    "key": "Binary-scratch",
    "name": "Binary-scratch"
  },
  {
    "key": "Golang",
    "name": "Golang"
  },
  {
    "key": "Golang-alpine",
    "name": "Golang-alpine"
  },
  {
    "key": "Golang-scratch",
    "name": "Golang-scratch"
  },
  {
    "key": "HTTPd",
    "name": "HTTPd"
  },
  {
    "key": "Node",
    "name": "Node"
  },
  {
    "key": "Node-alpine",
    "name": "Node-alpine"
  },
  {
    "key": "OpenJDK",
    "name": "OpenJDK"
  },
  {
    "key": "PHP",
    "name": "PHP"
  },
  {
    "key": "Python",
    "name": "Python"
  },
  {
    "key": "Python-alpine",
    "name": "Python-alpine"
  },
  {
    "key": "Python2",
    "name": "Python2"
  },
  {
    "key": "Ruby",
    "name": "Ruby"
  },
  {
    "key": "Ruby-alpine",
    "name": "Ruby-alpine"
  },
  {
    "key": "Rust",
    "name": "Rust"
  },
  {
    "key": "Swift",
    "name": "Swift"
  }
]
```

## Single Dockerfile template

Get a single Dockerfile template.

```plaintext
GET /templates/dockerfiles/:key
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `key`      | string | yes      | The key of the Dockerfile template |

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles/Binary"
```

Example response:

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
