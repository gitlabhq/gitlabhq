---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: .gitignore API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to retrieve .gitignore templates. For more information,
see the [Git documentation for `.gitignore`](https://git-scm.com/docs/gitignore).

Users with the Guest role can't access the `.gitignore` templates. For more information, see
[Project and group visibility](../../user/public_access.md).

## Get all `.gitignore` templates

Get a list of all `.gitignore` templates.

```plaintext
GET /templates/gitignores
```

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type   | Description |
|-----------|--------|-------------|
| `key`     | string | Key identifier for the `.gitignore` template. |
| `name`    | string | Display name of the `.gitignore` template. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores"
```

Example response:

```json
[
  {
    "key": "Actionscript",
    "name": "Actionscript"
  },
  {
    "key": "Ada",
    "name": "Ada"
  },
  {
    "key": "Agda",
    "name": "Agda"
  },
  {
    "key": "Android",
    "name": "Android"
  },
  {
    "key": "AppEngine",
    "name": "AppEngine"
  },
  {
    "key": "AppceleratorTitanium",
    "name": "AppceleratorTitanium"
  },
  {
    "key": "ArchLinuxPackages",
    "name": "ArchLinuxPackages"
  },
  {
    "key": "Autotools",
    "name": "Autotools"
  },
  {
    "key": "C",
    "name": "C"
  },
  {
    "key": "C++",
    "name": "C++"
  },
  {
    "key": "CFWheels",
    "name": "CFWheels"
  },
  {
    "key": "CMake",
    "name": "CMake"
  },
  {
    "key": "CUDA",
    "name": "CUDA"
  },
  {
    "key": "CakePHP",
    "name": "CakePHP"
  },
  {
    "key": "ChefCookbook",
    "name": "ChefCookbook"
  },
  {
    "key": "Clojure",
    "name": "Clojure"
  },
  {
    "key": "CodeIgniter",
    "name": "CodeIgniter"
  },
  {
    "key": "CommonLisp",
    "name": "CommonLisp"
  },
  {
    "key": "Composer",
    "name": "Composer"
  },
  {
    "key": "Concrete5",
    "name": "Concrete5"
  }
]
```

## Get a single `.gitignore` template

Get a single `.gitignore` template.

```plaintext
GET /templates/gitignores/:key
```

Supported attributes:

| Attribute | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `key`     | string | Yes      | Key of the `.gitignore` template. |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type   | Description |
|-----------|--------|-------------|
| `content` | string | Content of the `.gitignore` template. |
| `name`    | string | Display name of the `.gitignore` template. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores/Ruby"
```

Example response:

```json
{
  "name": "Ruby",
  "content": "*.gem\n*.rbc\n/.config\n/coverage/\n/InstalledFiles\n/pkg/\n/spec/reports/\n/spec/examples.txt\n/test/tmp/\n/test/version_tmp/\n/tmp/\n\n# Used by dotenv library to load environment variables.\n# .env\n\n## Specific to RubyMotion:\n.dat*\n.repl_history\nbuild/\n*.bridgesupport\nbuild-iPhoneOS/\nbuild-iPhoneSimulator/\n\n## Specific to RubyMotion (use of CocoaPods):\n#\n# We recommend against adding the Pods directory to your .gitignore. However\n# you should judge for yourself, the pros and cons are mentioned at:\n# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control\n#\n# vendor/Pods/\n\n## Documentation cache and generated files:\n/.yardoc/\n/_yardoc/\n/doc/\n/rdoc/\n\n## Environment normalization:\n/.bundle/\n/vendor/bundle\n/lib/bundler/man/\n\n# for a library or gem, you might want to ignore these files since the code is\n# intended to run in multiple environments; otherwise, check them in:\n# Gemfile.lock\n# .ruby-version\n# .ruby-gemset\n\n# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:\n.rvmrc\n"
}
```
