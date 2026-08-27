---
stage: Application Security Testing
group: Composition Analysis
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Gemnasium analyzer data
---

The following table lists the data available for the Gemnasium analyzer.

| Property \ Tool                               | Gemnasium |
|:----------------------------------------------|:---------:|
| Severity                                      | {{< yes >}} |
| Title                                         | {{< yes >}} |
| File                                          | {{< yes >}} |
| Start line                                    | {{< no >}} No |
| End line                                      | {{< no >}} No |
| External ID (for example, CVE)                | {{< yes >}} |
| URLs                                          | {{< yes >}} |
| Internal doc/explanation                      | {{< yes >}} |
| Solution                                      | {{< yes >}} |
| Confidence                                    | {{< no >}} No |
| Affected item (for example, class or package) | {{< yes >}} |
| Source code extract                           | {{< no >}} No |
| Internal ID                                   | {{< yes >}} |
| Date                                          | {{< yes >}} |
| Credits                                       | {{< yes >}} |

- {{< yes >}} => we have that data
- {{< no >}} No => we don't have that data, or we would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous, so they are sometimes normalized into common
values (for example, `severity`, `confidence`, etc).
