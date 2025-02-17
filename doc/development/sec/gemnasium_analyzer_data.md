---
stage: Application Security Testing
group: Composition Analysis
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Gemnasium analyzer data
---

The following table lists the data available for the Gemnasium analyzer.

| Property \ Tool                               | Gemnasium |
|:----------------------------------------------|:---------:|
| Severity                                      | {{< icon name="check-circle" >}} Yes |
| Title                                         | {{< icon name="check-circle" >}} Yes |
| File                                          | {{< icon name="check-circle" >}} Yes |
| Start line                                    | {{< icon name="dotted-circle" >}} No |
| End line                                      | {{< icon name="dotted-circle" >}} No |
| External ID (for example, CVE)                | {{< icon name="check-circle" >}} Yes |
| URLs                                          | {{< icon name="check-circle" >}} Yes |
| Internal doc/explanation                      | {{< icon name="check-circle" >}} Yes |
| Solution                                      | {{< icon name="check-circle" >}} Yes |
| Confidence                                    | {{< icon name="dotted-circle" >}} No |
| Affected item (for example, class or package) | {{< icon name="check-circle" >}} Yes |
| Source code extract                           | {{< icon name="dotted-circle" >}} No |
| Internal ID                                   | {{< icon name="check-circle" >}} Yes |
| Date                                          | {{< icon name="check-circle" >}} Yes |
| Credits                                       | {{< icon name="check-circle" >}} Yes |

- {{< icon name="check-circle" >}} Yes => we have that data
- {{< icon name="dotted-circle" >}} No => we don't have that data, or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous, so they are sometimes normalized into common
values (for example, `severity`, `confidence`, etc).
