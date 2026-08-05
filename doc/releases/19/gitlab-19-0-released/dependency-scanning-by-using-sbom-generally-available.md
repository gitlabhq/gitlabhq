---
title: Dependency scanning by using SBOM generally available
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20456"
categories: [ Software Composition Analysis ]
weight: 50
---

The GitLab SBOM-based dependency scanner is now generally available. Maven, Gradle, and Python
projects now have complete visibility into vulnerabilities across their full dependency tree,
including vulnerable packages introduced transitively, not just those declared directly.

The analyzer now includes automatic dependency resolution for Maven, Gradle, and Python projects.
When a lockfile or resolved dependency graph is not present, the analyzer automatically invokes tooling
to resolve the full transitive dependency graph before scanning. Dependency resolution is enabled by
default and requires little-to-no additional configuration beyond including the v2 Dependency Scanning template.

For projects where dependency resolution is not possible, the analyzer falls back to
manifest scanning. It parses `pom.xml`, `requirements.txt`, `build.gradle`, and
`build.gradle.kts` to identify direct dependencies. Manifest scanning ensures teams
always get a starting point for vulnerability coverage, even for projects without
lock or build files.

Manifest scanning is enabled by default and returns direct dependencies only.
For full transitive coverage, enable dependency resolution or provide a dependency lockfile or graph export manually.
