---
title: "GitLab Duo CLIでの画像コンテキスト"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/gitlab_duo_cli/use/#provide-images-as-context"
work_item: https://gitlab.com/groups/gitlab-org/modelops/applied-ml/code-suggestions/-/work_items/61
categories: [ Duo Developer ]
level: secondary
weight: 50
---

これまで、GitLab Duo CLIはテキストファイルを読み取ることができましたが、スクリーンショットや図をコンテキストとして使用することはできませんでした。
今回のリリースで、CLIをローカルでインタラクティブモードまたはヘッドレスモードで実行する際に、同じプロジェクト内のリポジトリの画像や、イシュー、マージリクエスト、コメントの添付ファイルを読み取れるようになりました。

画像コンテキストを使用するには、GitLab Duo CLI 9.27.0以降およびGitLabが管理するモデルが必要です。
