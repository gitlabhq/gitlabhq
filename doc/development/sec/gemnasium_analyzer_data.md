---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Gemnasium analyzer data

The following table lists the data available for the Gemnasium analyzer.

| Property \ Tool                               | Gemnasium               |
|:----------------------------------------------|:-----------------------:|
| Severity                                      | **{check-circle}**  Yes |
| Title                                         | **{check-circle}**  Yes |
| File                                          | **{check-circle}**  Yes |
| Start line                                    | **{dotted-circle}** No  |
| End line                                      | **{dotted-circle}** No  |
| External ID (for example, CVE)                | **{check-circle}**  Yes |
| URLs                                          | **{check-circle}**  Yes |
| Internal doc/explanation                      | **{check-circle}**  Yes |
| Solution                                      | **{check-circle}**  Yes |
| Confidence                                    | **{dotted-circle}** No  |
| Affected item (for example, class or package) | **{check-circle}**  Yes |
| Source code extract                           | **{dotted-circle}** No  |
| Internal ID                                   | **{check-circle}**  Yes |
| Date                                          | **{check-circle}**  Yes |
| Credits                                       | **{check-circle}**  Yes |

- **{check-circle}** Yes => we have that data
- **{dotted-circle}** No => we don't have that data, or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous, so they are sometimes normalized into common
values (for example, `severity`, `confidence`, etc).
