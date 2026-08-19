---
title: Gradle SBOMスキャンの依存関係解決
stage: software_supply_chain_security
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/#dependency-resolution"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/590734"
categories: [ Software Composition Analysis ]
weight: 30
---

SBOMを使用したGitLabの依存関係スキャンで、Gradleプロジェクトの依存関係グラフ（`gradle.graph.txt`）が自動生成されるようになりました。これまでは、Gradleの依存関係スキャンを実行するには、ビルドの一環として依存関係グラフを手動で生成する必要がありました。グラフファイルが存在しない場合、アナライザーが自動的に生成するようになったため、GradleをベースとするJavaおよびKotlinプロジェクトでこの手動作業が不要になりました。
