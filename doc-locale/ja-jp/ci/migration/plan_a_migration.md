---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 他のツールからGitLab CI/CDへの移行を計画する
description: Jenkins、GitHub Actionsなどから移行する。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

他のツールからGitLab CI/CDへの移行を開始する前に、まず移行計画を策定することから始める必要があります。

大規模な移行の最初のステップに関するアドバイスについては、まず[組織変更の管理](#manage-organizational-changes)に関するアドバイスを確認してください。

移行自体に関わるユーザーは、期待値を設定するための重要な技術的ステップとして、[移行を開始する前に尋ねるべき質問](#technical-questions-to-ask-before-starting-a-migration)を確認してください。CI/CDツールは、アプローチ、構造、および技術的な詳細が異なります。一部の概念は一対一でマップされますが、その他はインタラクティブな変換が必要です。

古いツールの動作を厳密に変換するのではなく、望ましい最終状態に焦点を当てることが重要です。

## 組織変更を管理する {#manage-organizational-changes}

GitLab CI/CDへの移行において重要な部分は、それに伴う文化的および組織的な変化であり、それらをうまく管理することです。

組織が役立つと報告しているいくつかの事柄:

- あなたの移行目標が何であるかという明確なビジョンを設定し、それを伝えることで、ユーザーはその努力が価値あるものである理由を理解するのに役立ちます。作業が完了すればその価値は明らかですが、進行中も人々が認識している必要があります。
- 関連するリーダーシップチームからの後援と連携は、前述の点に役立ちます。
- 何が異なるのかについてユーザーを教育する時間を費やし、このガイドを彼らと共有してください。
- 移行の一部を順序付けたり遅らせたりする方法を見つけることは、大いに役立ちます。しかし重要なのは、未移行（または部分的に移行された）の状態に長く放置しないようにすることです。
- GitLabのすべてのメリットを得るには、既存の設定を現在の問題を含めてそのまま移行するだけでは不十分です。GitLab CI/CDが提供する改善点を活用し、移行の一環として実装を更新してください。

## 移行を開始する前に尋ねるべき技術的な質問 {#technical-questions-to-ask-before-starting-a-migration}

CI/CDのニーズに関するいくつかの初期の技術的質問をすることで、移行要件を迅速に定義するのに役立ちます:

- このパイプラインを使用しているプロジェクトはいくつありますか？
- どのようなブランチ戦略が使用されていますか？フィーチャーブランチですか？Mainですか？リリースブランチですか？
- あなたのコードをビルドするためにどのようなツールを使用していますか？例えば、Maven、Gradle、またはNPMですか？
- あなたのコードをテストするためにどのようなツールを使用していますか？例えば、JUnit、Pytest、またはJestですか？
- 何かセキュリティスキャナーを使用していますか？
- ビルドされたパッケージはどこに保存していますか？
- あなたのコードをどのようにデプロイしますか？
- あなたのコードをどこにデプロイしますか？

## 関連トピック {#related-topics}

- Atlassian Bamboo ServerのCI/CDインフラストラクチャをGitLab CI/CDへ移行する方法、[パート1](https://about.gitlab.com/blog/migration-from-atlassian-bamboo-server-to-gitlab-ci/)および[パート2](https://about.gitlab.com/blog/how-to-migrate-atlassians-bamboo-servers-ci-cd-infrastructure-to-gitlab-ci-part-two/)
