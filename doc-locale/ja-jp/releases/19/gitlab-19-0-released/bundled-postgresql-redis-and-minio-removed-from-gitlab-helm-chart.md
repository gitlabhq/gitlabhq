---
title: バンドルされたPostgreSQL、Redis、MinIOがGitLab Helmチャートから削除
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590797"
categories: [ Cloud Native Installation ]
weight: 80
---

バンドルされているBitnami PostgreSQL、Bitnami Redis、MinIOのチャートは、GitLab 19.0においてGitLab HelmチャートおよびGitLab Operatorから代替なしで削除されます。これらのコンポーネントは概念実証およびテスト環境のみを対象としており、本番環境での使用は推奨されていません。これらのバンドルサービスのいずれかを使用してインスタンスを運用している場合は、GitLab 19.0へのアップグレード前に[移行ガイド](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)に従って外部サービスを設定してください。
