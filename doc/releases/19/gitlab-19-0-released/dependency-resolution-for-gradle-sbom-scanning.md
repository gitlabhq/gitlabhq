---
title: Dependency resolution for Gradle SBOM scanning
stage: software_supply_chain_security
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/#dependency-resolution"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/590734"
categories: [ Software Composition Analysis ]
weight: 30
---

GitLab dependency scanning using SBOM now automatically generates a dependency graph (`gradle.graph.txt`)
for Gradle projects. Previously, Gradle dependency scanning required
you to generate a dependency graph
manually as part of your build. Now, when a graph file is not available, the analyzer
generates one automatically, removing this manual step for Java and Kotlin projects using Gradle.
