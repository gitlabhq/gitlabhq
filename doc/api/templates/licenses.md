---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Licenses API

In GitLab, there is an API endpoint available for working with various open
source license templates. For more information on the terms of various
licenses, see [this site](https://choosealicense.com/) or any of the many other
resources available online.

## List license templates

Get all license templates.

```plaintext
GET /templates/licenses
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `popular` | boolean | no       | If passed, returns only popular licenses |

```shell
curl "https://gitlab.example.com/api/v4/templates/licenses?popular=1"
```

Example response:

```json
[
    {
        "key": "apache-2.0",
        "name": "Apache License 2.0",
        "nickname": null,
        "featured": true,
        "html_url": "http://choosealicense.com/licenses/apache-2.0/",
        "source_url": "http://www.apache.org/licenses/LICENSE-2.0.html",
        "description": "A permissive license that also provides an express grant of patent rights from contributors to users.",
        "conditions": [
            "include-copyright",
            "document-changes"
        ],
        "permissions": [
            "commercial-use",
            "modifications",
            "distribution",
            "patent-use",
            "private-use"
        ],
        "limitations": [
            "trademark-use",
            "no-liability"
        ],
        "content": "                                 Apache License\n                           Version 2.0, January 2004\n [...]"
    },
    {
        "key": "gpl-3.0",
        "name": "GNU General Public License v3.0",
        "nickname": "GNU GPLv3",
        "featured": true,
        "html_url": "http://choosealicense.com/licenses/gpl-3.0/",
        "source_url": "http://www.gnu.org/licenses/gpl-3.0.txt",
        "description": "The GNU GPL is the most widely used free software license and has a strong copyleft requirement. When distributing derived works, the source code of the work must be made available under the same license.",
        "conditions": [
            "include-copyright",
            "document-changes",
            "disclose-source",
            "same-license"
        ],
        "permissions": [
            "commercial-use",
            "modifications",
            "distribution",
            "patent-use",
            "private-use"
        ],
        "limitations": [
            "no-liability"
        ],
        "content": "                    GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007\n [...]"
    },
    {
        "key": "mit",
        "name": "MIT License",
        "nickname": null,
        "featured": true,
        "html_url": "http://choosealicense.com/licenses/mit/",
        "source_url": "http://opensource.org/licenses/MIT",
        "description": "A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
        "conditions": [
            "include-copyright"
        ],
        "permissions": [
            "commercial-use",
            "modifications",
            "distribution",
            "private-use"
        ],
        "limitations": [
            "no-liability"
        ],
        "content": "The MIT License (MIT)\n\nCopyright (c) [year] [fullname]\n [...]"
    }
]
```

## Single license template

Get a single license template. You can pass parameters to replace the license
placeholder.

```plaintext
GET /templates/licenses/:key
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `key`      | string | yes      | The key of the license template |
| `project`  | string | no       | The copyrighted project name |
| `fullname` | string | no       | The full-name of the copyright holder |

NOTE:
If you omit the `fullname` parameter but authenticate your request, the name of
the authenticated user replaces the copyright holder placeholder.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/templates/licenses/mit?project=My+Cool+Project"
```

Example response:

```json
{
    "key": "mit",
    "name": "MIT License",
    "nickname": null,
    "featured": true,
    "html_url": "http://choosealicense.com/licenses/mit/",
    "source_url": "http://opensource.org/licenses/MIT",
    "description": "A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
    "conditions": [
        "include-copyright"
    ],
    "permissions": [
        "commercial-use",
        "modifications",
        "distribution",
        "private-use"
    ],
    "limitations": [
        "no-liability"
    ],
    "content": "The MIT License (MIT)\n\nCopyright (c) 2016 John Doe\n [...]"
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
