---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Play
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.10で`google_play_integration`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111621)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/389611)になりました。機能フラグ`google_play_integration`は削除されました。

{{< /history >}}

この機能は、GitLabが開発した[Mobile DevOps](../../../ci/mobile_devops/_index.md)の一部です。この機能はまだ開発中ですが、次のことができます:

- [機能のリクエスト](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request)。
- [バグの報告](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug)。
- [フィードバックの共有](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback)。

Google Playインテグレーションを使用すると、CI/CDパイプラインを構成して、[Google Play Console](https://play.google.com/console/developers)に接続し、Androidデバイス用のアプリをビルドおよびリリースできます。

Google Playインテグレーションは、[fastlane](https://fastlane.tools/)ですぐに使用できます。このインテグレーションは、他のビルドツールでも使用できます。

## GitLabでインテグレーションを有効にする {#enable-the-integration-in-gitlab}

前提要件: 

- [Google Play Console](https://play.google.com/console/developers)デベロッパーアカウントが必要です。
- Google Cloud Consoleから[プロジェクトの新しいサービスアカウントキーを生成する](https://developers.google.com/android-publisher/getting_started)必要があります。

GitLabでGoogle Playインテグレーションを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Google Play**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスを選択します。
1. **Package name**（パッケージ名）に、アプリのパッケージ名を入力します（例: `com.gitlab.app_name`）。
1. オプション。**保護ブランチと保護タグのみ**で、**保護ブランチと保護タグにのみ変数を設定する**チェックボックスを選択します。
1. **サービスアカウントキー (.json)**で、キーファイルをドラッグまたはアップロードします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

インテグレーションを有効にすると、グローバル変数である`$SUPPLY_PACKAGE_NAME`と`$SUPPLY_JSON_KEY_DATA`がCI/CDで使用するために作成されます。

### CI/CD変数のセキュリティ {#cicd-variable-security}

`.gitlab-ci.yml`ファイルにプッシュされた悪意のあるコードは、`$SUPPLY_JSON_KEY_DATA`を含む変数を侵害し、サードパーティのサーバーに送信する可能性があります。詳細については、[CI/CD変数のセキュリティ](../../../ci/variables/_index.md#cicd-variable-security)を参照してください。

## fastlaneでインテグレーションを有効にする {#enable-the-integration-in-fastlane}

fastlaneでインテグレーションを有効にし、ビルドをGoogle Playの指定されたトラックにアップロードするには、アプリの`fastlane/Fastfile`に次のコードを追加します:

```ruby
upload_to_play_store(
  track: 'internal',
  aab: '../build/app/outputs/bundle/release/app-release.aab'
)
```
