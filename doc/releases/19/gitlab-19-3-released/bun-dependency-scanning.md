---
title: "Dependency scanning support for Bun"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/#supported-languages-and-files"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/592701
categories: [ Software Composition Analysis ]
level: secondary
---

In previous versions of GitLab, projects using the Bun JavaScript runtime and package
manager had no dependency scanning coverage.

Now, GitLab dependency scanning analyzes Bun projects by parsing `bun.lock` files
(the text-based JSONC format introduced in Bun 1.2).

Because Bun packages are sourced from the npm registry, the GitLab advisory
database already covers these dependencies with no additional configuration required.
Teams using Bun as an alternative to npm, yarn, or pnpm can now scan their projects
for known vulnerabilities as part of their standard CI/CD pipelines. Eligible findings
are also supported by dependency scanning auto-remediation.
