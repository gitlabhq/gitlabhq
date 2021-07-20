---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project templates API **(FREE)**

This API is a project-specific version of these endpoints:

- [Dockerfile templates](templates/dockerfiles.md)
- [Gitignore templates](templates/gitignores.md)
- [GitLab CI/CD Configuration templates](templates/gitlab_ci_ymls.md)
- [Open source license templates](templates/licenses.md)
- [Issue and merge request templates](../user/project/description_templates.md)
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37890) in GitLab 13.3)

It deprecates these endpoints, which are scheduled for removal in API version 5.

In addition to templates common to the entire instance, project-specific
templates are also available from this API endpoint.

Support for [Group-level file templates](../user/group/index.md#group-file-templates) **(PREMIUM)**
was [added](https://gitlab.com/gitlab-org/gitlab/-/issues/5987)
in GitLab 11.5

## Get all templates of a particular type

```plaintext
GET /projects/:id/templates/:type
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `id`      | integer / string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `type`     | string | yes | The type of the template. Accepted values are: `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues`, `merge_requests` |

Example response (licenses):

```json
[
  {
    "key": "epl-1.0",
    "name": "Eclipse Public License 1.0"
  },
  {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0"
  },
  {
    "key": "unlicense",
    "name": "The Unlicense"
  },
  {
    "key": "agpl-3.0",
    "name": "GNU Affero General Public License v3.0"
  },
  {
    "key": "gpl-3.0",
    "name": "GNU General Public License v3.0"
  },
  {
    "key": "bsd-3-clause",
    "name": "BSD 3-clause \"New\" or \"Revised\" License"
  },
  {
    "key": "lgpl-2.1",
    "name": "GNU Lesser General Public License v2.1"
  },
  {
    "key": "mit",
    "name": "MIT License"
  },
  {
    "key": "apache-2.0",
    "name": "Apache License 2.0"
  },
  {
    "key": "bsd-2-clause",
    "name": "BSD 2-clause \"Simplified\" License"
  },
  {
    "key": "mpl-2.0",
    "name": "Mozilla Public License 2.0"
  },
  {
    "key": "gpl-2.0",
    "name": "GNU General Public License v2.0"
  }
]
```

## Get one template of a particular type

```plaintext
GET /projects/:id/templates/:type/:name
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `id`      | integer / string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `type`     | string | yes| The type of the template. One of: `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues`, or `merge_requests`. |
| `name`     | string | yes      | The key of the template, as obtained from the collection endpoint |
| `source_template_project_id`   | integer | no      | The project ID where a given template is being stored. This is useful when multiple templates from different projects have the same name. If multiple templates have the same name, the match from `closest ancestor` is returned if `source_template_project_id` is not specified |
| `project`  | string | no       | The project name to use when expanding placeholders in the template. Only affects licenses |
| `fullname` | string | no       | The full name of the copyright holder to use when expanding placeholders in the template. Only affects licenses |

Example response (Dockerfile):

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```

Example response (license):

```json
{
  "key": "mit",
  "name": "MIT License",
  "nickname": null,
  "popular": true,
  "html_url": "http://choosealicense.com/licenses/mit/",
  "source_url": "https://opensource.org/licenses/MIT",
  "description": "A short and simple permissive license with conditions only requiring preservation of copyright and license notices. Licensed works, modifications, and larger works may be distributed under different terms and without source code.",
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
    "liability",
    "warranty"
  ],
  "content": "MIT License\n\nCopyright (c) 2018 [fullname]\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n"
}
```
