---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Apple App Store Connect
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.8で`apple_app_store_integration`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104888)されました。デフォルトでは無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/385335)になりました。機能フラグ`apple_app_store_integration`は削除されました。

{{< /history >}}

この機能は、GitLabが開発した[Mobile DevOps](../../../ci/mobile_devops/_index.md)の一部です。この機能はまだ開発中ですが、次のことができます:

- [機能のリクエスト](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request)。
- [バグの報告](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug)。
- [フィードバックの共有](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback)。

Apple App Store Connectインテグレーションを使用して、CI/CDパイプラインを[App Store Connect](https://appstoreconnect.apple.com)に接続するように設定します。このインテグレーションを使用すると、iOS、iPadOS、macOS、tvOS、watchOS用のアプリをビルドしてリリースできます。

Apple App Store Connectインテグレーションは、[fastlane](https://fastlane.tools/)ですぐに使用できます。このインテグレーションは、他のビルドツールでも使用できます。

## GitLabでインテグレーションを有効にする {#enable-the-integration-in-gitlab}

前提要件: 

- [Apple Developer Program](https://developer.apple.com/programs/enroll/)に登録されているApple IDが必要です。
- Apple App Store Connectポータルで、プロジェクトの[新しいプライベートキーを生成](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)する必要があります。

GitLabでApple App Store Connectインテグレーションを有効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Apple App Store Connect**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. Apple App Store Connectの設定情報を入力します:
   - **Issuer ID**: Apple App Store Connect発行元ID。
   - **Key ID**（キーID）: 生成されたプライベートキーのキーID。
   - **秘密キー**: 生成されたプライベートキー。このキーは1回しかダウンロードできません。
   - **保護ブランチと保護タグのみ**: 保護ブランチとタグでのみ変数を設定する場合に有効にします。
1. **変更を保存**を選択します。

インテグレーションを有効にした後:

- グローバル変数`$APP_STORE_CONNECT_API_KEY_ISSUER_ID`、`$APP_STORE_CONNECT_API_KEY_KEY_ID`、`$APP_STORE_CONNECT_API_KEY_KEY`、`$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`がCI/CDで使用するために作成されます。
- `$APP_STORE_CONNECT_API_KEY_KEY`には、Base64エンコードされたプライベートキーが含まれています。
- `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`は常に`true`です。

## セキュリティに関する考慮事項 {#security-considerations}

### CI/CD変数のセキュリティ {#cicd-variable-security}

`.gitlab-ci.yml`ファイルにプッシュされた悪意のあるコードは、`$APP_STORE_CONNECT_API_KEY_KEY`を含む変数を侵害し、サードパーティのサーバーに送信する可能性があります。詳細については、[CI/CD変数のセキュリティ](../../../ci/variables/_index.md#cicd-variable-security)を参照してください。

## fastlaneでインテグレーションを有効にする {#enable-the-integration-in-fastlane}

fastlaneでインテグレーションを有効にして、TestFlightまたはパブリックApp Storeリリースをアップロードするには、アプリの`fastlane/Fastfile`に次のコードを追加します:

```ruby
app_store_connect_api_key
```
