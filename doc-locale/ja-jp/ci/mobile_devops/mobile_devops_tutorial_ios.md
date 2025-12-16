---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab Mobile DevOpsでiOSアプリをビルドする'
---

このチュートリアルでは、GitLab CI/CDを使用して、iOSモバイルアプリをビルドし、認証情報で署名し、アプリストアに配布するパイプラインを作成します。

モバイルDevOpsを設定するには:

1. [ビルド環境をセットアップする](#set-up-your-build-environment)
1. [fastlaneでコード署名を構成する](#configure-code-signing-with-fastlane)
1. [Apple Storeのインテグレーションとfastlaneでアプリ配布をセットアップする](#set-up-app-distribution-with-apple-store-integration-and-fastlane)

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下を確認してください:

- CI/CDパイプラインへのアクセス権を持つGitLabアカウント
- GitLabリポジトリにあるモバイルアプリのコード
- Appleデベロッパーアカウント
- [`fastlane`](https://fastlane.tools)がローカルにインストールされている

## ビルド環境をセットアップする {#set-up-your-build-environment}

[GitLabホストされたRunner](../runners/_index.md)を使用するか、ビルド環境を完全に制御するために[自己管理Runner](https://docs.gitlab.com/runner/#use-self-managed-runners)をセットアップします。

1. `.gitlab-ci.yml`ファイルをリポジトリのルートに作成します。
1. [サポートされているmacOSイメージ](../runners/hosted_runners/macos.md#supported-macos-images)を追加して、[macOS GitLabホストされたRunner](../runners/hosted_runners/macos.md) (ベータ) でジョブを実行します:

   ```yaml
   test:
     image: macos-14-xcode-15
     stage: test
     script:
       - fastlane test
     tags:
       - saas-macos-medium-m1
   ```

## fastlaneでコード署名を構成する {#configure-code-signing-with-fastlane}

iOSのコード署名をセットアップするには、fastlaneを使用して署名付き証明書をGitLabにアップロードします:

1. fastlaneを初期化します:

   ```shell
   fastlane init
   ```

1. 設定で`Matchfile`を生成します:

   ```shell
   fastlane match init
   ```

1. Appleデベロッパーポータルで証明書とプロファイルを生成し、それらのファイルをGitLabにアップロードします:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match development
   ```

1. オプション。すでにプロジェクトの署名証明書とプロビジョニングプロファイルを作成している場合は、`fastlane match import`を使用して既存のファイルをGitLabに読み込むます:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match import
   ```

ファイルのパスを入力するように求められます。詳細を入力すると、ファイルがアップロードされ、プロジェクトのCI/CD設定に表示されます。インポート中に`git_url`を求められた場合は、空白のままにして<kbd>Enter</kbd>キーを押しても安全です。

以下は、この構成のサンプル`fastlane/Fastfile`ファイルと`.gitlab-ci.yml`ファイルです:

- `fastlane/Fastfile`: 

  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Build and sign the application for development"
    lane :build do
      setup_ci

      match(type: 'development', readonly: is_ci)

      build_app(
        project: "ios demo.xcodeproj",
        scheme: "ios demo",
        configuration: "Debug",
        export_method: "development"
      )
    end
  end
  ```

- `.gitlab-ci.yml`: 

  ```yaml
  build_ios:
    image: macos-12-xcode-14
    stage: build
    script:
      - fastlane build
    tags:
      - saas-macos-medium-m1
  ```

## Apple Storeのインテグレーションとfastlaneでアプリ配布をセットアップする {#set-up-app-distribution-with-apple-store-integration-and-fastlane}

署名付きのビルドは、モバイルDevOps配布インテグレーションを使用してApple App Storeにアップロードできます。

前提要件: 

- Appleデベロッパープログラムに登録されたApple IDが必要です。
- Apple App Store Connectポータルで、プロジェクトの新しいプライベートキーを生成する必要があります。

Apple Storeのインテグレーションとfastlaneを使用してiOSディストリビューションを作成するには:

1. App Store Connect APIのAPIキーを生成します。Apple App Store Connectポータルで、[プロジェクトの新しいプライベートキーを生成](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)します。
1. Apple App Store Connectのインテグレーションを有効にします:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **設定** > **インテグレーション**を選択します。
   1. **Apple App Store Connect**を選択します。
   1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
   1. Apple App Store Connectの構成情報を入力してください:
      - **Issuer ID**: Apple App Store Connect発行者ID。
      - **Key ID**: 生成されたプライベートキーのキーID。
      - **秘密キー**: 生成されたプライベートキー。このキーは一度しかダウンロードできません。
      - **保護ブランチと保護タグのみ**: 保護ブランチとタグ付けでのみ変数を設定できるようにします。
   1. **変更を保存**を選択します。
1. リリースステップをパイプラインおよびfastlane設定に追加します。

以下はサンプルの`fastlane/Fastfile`です:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and sign the application for distribution, upload to TestFlight"
  lane :beta do
    setup_ci

    match(type: 'appstore', readonly: is_ci)

    app_store_connect_api_key

    increment_build_number(
      build_number: latest_testflight_build_number(initial_build_number: 1) + 1,
      xcodeproj: "ios demo.xcodeproj"
    )

    build_app(
      project: "ios demo.xcodeproj",
      scheme: "ios demo",
      configuration: "Release",
      export_method: "app-store"
    )

    upload_to_testflight
  end
end
```

以下はサンプルの`.gitlab-ci.yml`です:

```yaml
beta_ios:
  image: macos-12-xcode-14
  stage: beta
  script:
    - fastlane beta
```

おつかれさまでした。これで、アプリは自動ビルド、署名、配布用にセットアップされました。最初のパイプラインをトリガーするために、マージリクエストを作成してみてください。

## サンプルプロジェクト {#sample-projects}

ビルド、署名、およびモバイルアプリをリリースするように構成されたパイプラインを備えた、サンプルモバイルDevOpsプロジェクトは、以下で利用できます:

- Android
- Flutter
- iOS

[モバイルDevOpsデモプロジェクト](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/)グループのすべてのプロジェクトを表示します。
