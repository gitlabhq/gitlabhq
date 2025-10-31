---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab.comのコンピューティング時間のコスト要素設定を構成します。
title: GitLab.comのコンピューティング時間管理
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comの管理者は、[GitLab Self-Managed](compute_minutes.md)で利用できるコンピューティング時間を超える追加のコントロールが可能です。

## コスト要素の設定 {#set-cost-factors}

前提要件: 

- GitLab.comの管理者である必要があります。

Runnerのコスト要素を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD > Runners**を選択します。
1. 更新するRunnerで、**編集**（{{< icon name="pencil" >}}）を選択します。
1. **パブリックプロジェクトのコンピューティングコスト要素**テキストボックスに、パブリックコスト要素を入力します。
1. **非公開プロジェクトのコンピューティングコスト要素**テキストボックスに、非公開コスト要素を入力します。
1. **変更を保存**を選択します。

## コミュニティのコントリビュートのコスト要素を削減 {#reduce-cost-factors-for-community-contributions}

`ci_minimal_cost_factor_for_gitlab_namespaces`機能フラグがネームスペースに対して有効になっている場合、有効になっているネームスペース内のGitLabプロジェクトをターゲットとするフォークしたマージリクエストパイプラインは、削減されたコスト要素を使用します。これにより、コミュニティのコントリビュートが過度のコンピューティング時間を消費することがなくなります。

前提要件: 

- 機能フラグを制御できる必要があります。
- コスト要素の削減を有効にするネームスペースIDが必要です。

ネームスペースが削減されたコスト要素を使用できるようにするには:

1. 含めるネームスペースIDの[機能フラグを有効にする](../feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags) `ci_minimal_cost_factor_for_gitlab_namespaces`。

この機能は、GitLab.comでのみ使用することをお勧めします。コミュニティのコントリビューターは、GitLabプロジェクトをターゲットとするマージリクエストにないパイプラインを実行するときに時間が累積するのを避けるために、コントリビュートのためにコミュニティフォークを使用する必要があります。
