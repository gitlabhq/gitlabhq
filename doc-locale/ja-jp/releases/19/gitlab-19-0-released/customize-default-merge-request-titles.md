---
title: デフォルトのマージリクエストタイトルをカスタマイズする
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/project/merge_requests/title_templates/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/16080"
categories: [ Code Review Workflow ]
weight: 100
---

以前のバージョンのGitLabでは、新しいマージリクエストのデフォルトタイトルはソースブランチまたは最初のコミットから生成されており、プロジェクト全体で一貫した命名規則を強制することはできませんでした。

今回のリリースで、プロジェクトごとにデフォルトのマージリクエストタイトルテンプレートを設定できるようになりました。テンプレートでは、ソースブランチ、ターゲットブランチ、最初のコミットのサブジェクト、リンクされたイシューID、イシュータイトル、ソースブランチ名の人間が読みやすい形式などの変数を使用できます。たとえば、テンプレート`Resolve %{issue_id} "%{issue_title}"`は`Resolve 123 "Fix login bug"`のようなタイトルを生成します。マージリクエストを作成する前にタイトルを編集することも引き続き可能です。
