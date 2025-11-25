---
stage: Container
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 保護されたコンテナリポジトリ
description: GitLabの保護されたコンテナリポジトリは、イメージのプッシュまたは削除を実行できるユーザーロールを制限します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で`container_registry_protected_containers`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463669)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- GitLab 17.8の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/429074)で有効になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)になりました。機能フラグ`container_registry_protected_containers`は削除されました。

{{< /history >}}

デフォルトでは、少なくともデベロッパーロールを持つすべてのユーザーが、コンテナイメージをコンテナリポジトリとの間でプッシュおよび削除できます。コンテナリポジトリを保護して、コンテナリポジトリ内のコンテナイメージを変更できるユーザーを制限します。

コンテナリポジトリが保護されている場合、デフォルトの動作では、コンテナリポジトリとそのイメージに対して次の制限が適用されます:

| アクション                                                                                   | 最低限必要なロール         |
|------------------------------------------------------------------------------------------|----------------------|
| コンテナリポジトリとそのコンテナイメージを保護します。                                 | メンテナーロール。 |
| コンテナリポジトリに新しいイメージをプッシュまたは作成します。                                    | [**プッシュに必要な最小アクセスレベル**](#create-a-container-repository-protection-rule)設定で設定されたロール。 |
| コンテナリポジトリ内の既存のイメージをプッシュまたは更新します。                              | [**プッシュに必要な最小アクセスレベル**](#create-a-container-repository-protection-rule)設定で設定されたロール。 |
| デプロイトークンを使用して、コンテナリポジトリ内の既存のイメージをプッシュ、作成、または更新します。 | 該当なし。デプロイトークンは、保護されていないリポジトリで使用できますが、スコープに関係なく、コンテナイメージを保護されたコンテナリポジトリにプッシュするために使用することはできません。 |

ワイルドカード（`*`）を使用して、同じコンテナ保護ルールで複数のコンテナリポジトリを保護できます。たとえば、CI/CDパイプライン中にビルドされた一時的なコンテナイメージを含む、さまざまなコンテナリポジトリを保護できます。

次の表に、複数のコンテナリポジトリに一致するコンテナ保護ルールの例を示します:

| ワイルドカードを含むパスパターン | 一致するコンテナリポジトリの例 |
|----------------------------|-----------------------------------------|
| `group/container-*`        | `group/container-prod`、`group/container-prod-sha123456789` |
| `group/*container`         | `group/container`、`group/prod-container`、`group/prod-sha123456789-container` |
| `group/*container*`        | `group/container`、`group/prod-sha123456789-container-v1` |

同じコンテナリポジトリに複数の保護ルールを適用できます。少なくとも1つの保護ルールが一致する場合、コンテナリポジトリは保護されます。

## コンテナリポジトリ保護ルールの作成 {#create-a-container-repository-protection-rule}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146523)されました。

{{< /history >}}

前提要件:

- メンテナーロール以上が必要です。

保護ルールを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **コンテナレジストリ**を展開します。
1. **保護されたコンテナリポジトリ**で、**保護ルールを追加する**を選択します。
1. フィールドに入力します:
   - **リポジトリパスパターン**は、保護するコンテナリポジトリのパスです。このパターンには、ワイルドカード（`*`）を含めることができます。
   - **プッシュに必要な最小アクセスレベル**は、保護されたコンテナリポジトリのパスへのプッシュ（作成または更新）に必要な最小アクセスレベルについて説明します。
1. **保護**を選択します。

保護ルールが作成され、コンテナリポジトリが保護されました。

## コンテナリポジトリ保護ルールの削除 {#delete-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146622)されました。

{{< /history >}}

前提要件:

- メンテナーロール以上が必要です。

保護ルールを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **コンテナレジストリ**を展開します。
1. **保護されたコンテナリポジトリ**で、削除する保護ルールの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**削除**を選択します。

保護ルールが削除され、コンテナリポジトリは保護されなくなりました。
