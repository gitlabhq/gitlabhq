---
title: CI/CDカタログコンポーネントの詳細な使用状況分析
stage: verify
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../ci/components/#view-component-usage-details"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/579460"
categories: [ Component Catalog ]
weight: 80
---

GitLabカタログでCI/CDコンポーネントを管理する際、アップグレードの管理、コンプライアンスの徹底、破壊的な変更の周知には、使用状況の詳細が不可欠です。
どのプロジェクトがコンポーネントを使用しているか、またどのバージョンを使用しているかを把握する必要があります。
以前はこの情報を確認する手段がなく、適切なメンテナーへの通知、安全な廃止計画の策定、最新のセキュリティパッチへの追従が困難でした。

カタログリソースページのコンポーネント使用状況詳細ビューでは、各コンポーネントを使用しているプロジェクト、実行中のバージョン、最新バージョンかどうかを正確に確認できるようになりました。古いバージョンを使用しているプロジェクトは上部に表示されるため、優先的にアプローチし、セキュリティ修正の導入を促進して、組織全体でスムーズなアップグレードパスを確保できます。
