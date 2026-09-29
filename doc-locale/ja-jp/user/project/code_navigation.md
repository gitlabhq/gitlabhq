---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コードナビゲーション
description: GitLab Orbitのナレッジグラフを使用して、シンボルがどこで定義され、呼び出されているかを検索します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.0で`orbit_code_intelligence`[機能フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234404)されました。デフォルトでは無効になっています。
- GitLab 19.4の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/work_items/599054)になりました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

コードナビゲーションは、不慣れなコードや、それがプロジェクトの他の部分とどのように関連しているかを理解するのに役立ちます。

コードナビゲーションは、[GitLab Orbit](https://docs.gitlab.com/orbit/indexed-data/)がコードから構築し、変更をプッシュするたびに更新されるナレッジグラフを読み取ります。そのグラフから、プロジェクト内のファイル、それらが定義するクラス、モジュール、メソッド、関数、そしてそれらのシンボルのどれが互いを呼び出しているかを読み取ります。インデクサーやCI/CDジョブは必要ありません。

選択したシンボルについて、コードナビゲーションは以下を表示します:

- 参照: このシンボルを呼び出すプロジェクト内の場所で、呼び出し元カウントとしても表示されます。
- 呼び出し: このシンボルが呼び出すシンボル。
- 定義: シンボルが定義されているファイルと行へのリンク。

## ファイルのコードナビゲーションを表示 {#view-code-navigation-for-a-file}

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーのロール。
- プロジェクトのトップレベルグループで[GitLab Orbitが有効化されている](https://docs.gitlab.com/orbit/remote/getting-started/)こと。
- プロジェクトのデフォルトブランチ上のファイル。GitLab Orbitは他のブランチをインデックス付けしません。

ファイルのコードナビゲーションを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**コード** > **リポジトリ**を選択します。
1. デフォルトブランチ上のファイルを選択します。
1. ファイルの右上隅で、**コードナビゲーション**（{{< icon name="code" >}}）を選択します。

最近、トップレベルグループでGitLab Orbitを有効にした場合、[インデックス作成](https://docs.gitlab.com/orbit/remote/indexing/)がまだ進行中の可能性があります。インデックス作成が完了すると、パネルにシンボルがリスト表示されます。

シンボルがどこで使われているかを確認するには:

1. パネルでシンボルを選択します。
1. **参照**を選択すると、そのシンボルを呼び出すシンボルが表示され、**呼び出し**を選択すると、そのシンボルが呼び出すシンボルが表示されます。
1. 結果を選択すると、一致する行でそのファイルが開きます。

シンボルの全リストに戻るには、**シンボルに戻る**を選択します。

## サポートされている言語 {#supported-languages}

コードナビゲーションは、GitLab Orbitがインデックス付けする言語を対象としています。最新のリストについては、[GitLab Orbit](https://docs.gitlab.com/orbit/)のドキュメントを参照してください。
