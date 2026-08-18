---
title: ビルトインのプロジェクトテンプレートの無効化
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
documentation_link: "../../../administration/project_templates#built-in-project-templates"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21356
categories: [ Source Code Management ]
level: secondary
weight: 50
---

組織がカスタムプロジェクトテンプレートを使用している場合、ビルトインのベンダーテンプレートがテンプレート選択画面に不要な項目を追加したり、サーバーサイドフックやその他のリポジトリ制御を回避したりする可能性があります。

管理者は、**管理者**エリアからグローバルに、またはサブグループのグループレベルで、プロジェクトテンプレートを無効化できるようになりました。この設定は自動的にカスケードされるため、グループごとに個別に設定する必要はありません。管理者は設定値を強制することで、グループやサブグループが設定を上書きできないようにすることも可能です。インスタンスおよびグループの設定は、REST APIおよびGraphQL APIでも管理できます。
GitLab.comでは、グループレベルの設定のみ利用可能です。
