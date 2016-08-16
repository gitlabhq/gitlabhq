# Licenses

## List license templates

Get all license templates.

```
GET /licenses
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `popular` | boolean | no       | If passed, returns only popular licenses |

```bash
curl https://gitlab.example.com/api/v3/licenses?popular=1
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

```
GET /licenses/:key
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `key`      | string | yes      | The key of the license template |
| `project`  | string | no       | The copyrighted project name |
| `fullname` | string | no       | The full-name of the copyright holder |

>**Note:**
If you omit the `fullname` parameter but authenticate your request, the name of
the authenticated user will be used to replace the copyright holder placeholder.

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/licenses/mit?project=My+Cool+Project
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
