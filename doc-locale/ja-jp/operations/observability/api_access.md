---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: GitLab可観測性APIを使用して、トレース、メトリクス、ログをプログラムでクエリします。
ignore_in_report: true
title: 可観測性アクセスAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

GitLab可観測性APIを使用して、トレース、メトリクス、ログをクエリし、ダッシュボードとアラートをプログラムで管理します。

## 前提条件 {#prerequisites}

- グループで可観測性を有効にする必要があります。セットアップ手順については、[GitLab.comでの可観測性のセットアップ](setup_gitlab_com.md)または[GitLab Self-Managedでの可観測性のセットアップ](setup_self_managed.md)を参照してください。
- グループのデベロッパー、メンテナー、またはオーナーロールが必要です。

## APIキーを取得 {#get-your-api-key}

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**可観測性** > **API Keys**を選択します。
1. APIキーをコピーします。

APIリクエストを行う際には、このキーを`SIGNOZ-API-KEY`ヘッダーで使用します。

## APIエンドポイント {#api-endpoint}

APIエンドポイントは、GitLabの提供形態によって異なります。

### GitLab.com {#gitlabcom}

APIベースURLは次のパターンに従います:

```plaintext
https://<group_id>.gitlab-o11y.com
```

`<group_id>`をGitLabグループIDに置き換えます。

### GitLab Self-Managed {#gitlab-self-managed}

APIベースURLは、グループ用に`o11y_service_url`として設定したURLと同じです。例: 

```plaintext
http://<your-instance-ip>:8080
```

## APIリクエストを行う {#make-api-requests}

各リクエストにAPIキーを`SIGNOZ-API-KEY`ヘッダーに含めます。

次の例では、ヘルスエンドポイントをクエリします:

```shell
curl --header "SIGNOZ-API-KEY: <your_api_key>" \
  https://<group_id>.gitlab-o11y.com/api/v1/health
```

`<your_api_key>`を**API Keys**ページのキーに、`<group_id>`をGitLabグループID (またはSelf-ManagedインスタンスのURL) に置き換えます。

## 利用可能なAPIエンドポイント {#available-api-endpoints}

GitLab可観測性はSigNoz APIを使用します。利用可能なエンドポイント、リクエストとレスポンスの形式、および使用例の完全なリストについては、[SigNoz API参照](https://signoz.io/api-reference/)を参照してください。

## 関連トピック {#related-topics}

- [GitLab可観測性にテレメトリデータを送信する](send.md)
- [可観測性のトラブルシューティング](troubleshooting.md)
