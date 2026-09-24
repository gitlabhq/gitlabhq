---
title: Additional feature enhancements
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
co_create: true
documentation_link: "../../../api/job_artifacts/#download-job-artifacts-by-job-id"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518
categories: [ Job Artifacts ]
level: secondary
---

Other improvements in this release include:

- Fetch a specific report artifact from the API, restricted to downloadable types and gated by a
  per-artifact authorization check. For example, use
  `GET /projects/:id/jobs/:job_id/artifacts?file_type=junit` for a JUnit file.
- Administrators can let clients choose between a direct 302 redirect and a proxied transfer for
  job artifact and package downloads.
- The pipeline editor now validates CI/CD keywords the backend already supported.
- An email with an empty subject line now opens a Service Desk ticket instead of bouncing.
- Raise dependency resolution limits yourself with two new timeout inputs on the
  `Dependency-Scanning.v2` template.
- Administrators can set achievements to appear on profiles without each person accepting an
  emailed link.

Thank you to the following users for these contributions!

- [Andreas Kunze](https://gitlab.com/and2345) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518))
- [André Düwel](https://gitlab.com/duewel1982) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252350))
- [Paweł Farys](https://gitlab.com/vertisan) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250636))
- [Praveen Arimbrathodiyil](https://gitlab.com/pravi) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248600))
- [Niklas van Schrick](https://gitlab.com/Taucher2003) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249426))
- [BoxBoxJason](https://gitlab.com/BoxBoxJason) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249893))
