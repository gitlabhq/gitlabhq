---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: あなたのGitLabインスタンスのスニペット設定を構成します。
title: スニペット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

あなたのインスタンスでスニペットの悪用を防ぐため、ユーザーがスニペットを作成または更新する際に適用される最大スニペットサイズを構成します。既存のスニペットは、ユーザーが更新し、そのコンテンツが変更されない限り、制限の影響を受けません。

デフォルトの制限は52428800バイト（50 MB）です。

## スニペットサイズ制限の構成 {#configure-the-snippet-size-limit}

スニペットサイズ制限を構成するには、Railsコンソールまたは[アプリケーション設定API](../../api/settings.md)を使用します。

制限はバイト単位である必要があります。

この設定は、[**管理者**エリアの設定](../settings/_index.md)では利用できません。

### Railsコンソールの使用 {#use-the-rails-console}

Railsコンソールからこの設定を構成するには:

1. [Railsコンソールを開始](../operations/rails_console.md#starting-a-rails-console-session)します。
1. スニペットの最大ファイルサイズを更新します:

   ```ruby
   ApplicationSetting.first.update!(snippet_size_limit: 50.megabytes)
   ```

現在の値を取得するには、Railsコンソールを開始して実行します:

  ```ruby
  Gitlab::CurrentSettings.snippet_size_limit
  ```

### APIを使用する {#use-the-api}

アプリケーション設定APIを使用して制限を設定するには（[他のいずれかの設定を更新する](../../api/settings.md#update-application-settings)のと同様に）、このコマンドを使用します:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800"
```

APIから[現在の値を取得する](../../api/settings.md#retrieve-details-on-current-application-settings)には:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

## 関連トピック {#related-topics}

- [ユーザースニペット](../../user/snippets.md)
