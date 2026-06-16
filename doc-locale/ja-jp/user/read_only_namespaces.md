---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 読み取り専用のネームスペースとプロジェクト
---

## 読み取り専用ネームスペース {#read-only-namespaces}

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com

{{< /details >}}

ネームスペースが[Freeユーザー制限](free_user_limit.md)を超過し、かつネームスペースの表示レベルがプライベートである場合に、読み取り専用状態になります。

ネームスペースおよびそのプロジェクトの読み取り専用状態を解除するには、次のいずれかの操作を実行できます:

- [お使いのネームスペースでメンバー数を減らす](free_user_limit.md#manage-members-in-your-group-namespace)。
- [無料トライアルを開始する](https://gitlab.com/-/trial_registrations/new)と、無制限のメンバーが含まれます。
- [有償プランを購入する](https://about.gitlab.com/pricing/)。

### 制限されたアクション {#restricted-actions}

ネームスペースが読み取り専用状態の場合、次の表にリストされているアクションを実行できません。制限されたアクションを実行しようとすると、`404`エラーが発生する場合があります。

| 機能 | 制限されるアクション |
|---------|-------------------|
| コンテナレジストリ | クリーンアップポリシーの作成、編集、削除。<br> コンテナレジストリにイメージをプッシュする。 |
| マージリクエスト | マージリクエストを作成および更新する。 |
| パッケージレジストリ | パッケージを公開する。 |
| CI/CD | パイプラインの作成、編集、管理、実行。<br>  ビルドの作成、編集、管理、実行。<br>  管理者環境の作成と編集。<br> 管理者デプロイの作成と編集。<br>  管理者クラスターの作成と編集。<br> 管理者リリースの作成と編集。 |
| ネームスペース | **無料ユーザー数の上限を超えた場合**: 新しいユーザーを招待する。 |

## 読み取り専用プロジェクト {#read-only-projects}

{{< details >}}

- プラン: Free、Premium、Ultimate

{{< /details >}}

プロジェクトが以下のストレージ制限を超過した場合、読み取り専用状態になります:

- Freeティアの場合、ネームスペース内のいずれかのプロジェクトが[Free制限](storage_usage_quotas.md#free-limit)を超過したとき。
- PremiumおよびUltimateティアの場合、ネームスペース内のいずれかのプロジェクトが[固定プロジェクト制限](storage_usage_quotas.md#fixed-project-limit)を超過したとき。

### 制限されたアクション {#restricted-actions-1}

ストレージ制限によりプロジェクトが読み取り専用の場合、プロジェクトのリポジトリにプッシュしたり、ラージファイル（LFS）を追加したりすることはできません。プロジェクトまたはネームスペースページの上部にバナーが表示され、読み取り専用ステータスが示されます。
