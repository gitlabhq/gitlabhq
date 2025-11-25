---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab Mobile DevOpsでAndroidアプリをビルドする'
---

このチュートリアルでは、GitLab CI/CDを使用してAndroidモバイルアプリをビルドし、認証情報で署名し、アプリストアに配布するパイプラインを作成します。

モバイルDevOpsをセットアップするには、次の手順を実行します:

1. [ビルド環境をセットアップする](#set-up-your-build-environment)
1. [fastlaneとGradleでコード署名を構成する](#configure-code-signing-with-fastlane-and-gradle)
1. [Google Playのインテグレーションとfastlaneを使用してAndroidアプリの配布をセットアップする](#set-up-android-apps-distribution-with-google-play-integration-and-fastlane)

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下を確認してください:

- CI/CDパイプラインにアクセスできるGitLabアカウント
- GitLabリポジトリ内のモバイルアプリコード
- Google Playデベロッパーアカウント
- [`fastlane`](https://fastlane.tools)をローカルにインストール

## ビルド環境をセットアップする {#set-up-your-build-environment}

[GitLabホストされたRunner](../runners/_index.md)を使用するか、[自己管理Runner](https://docs.gitlab.com/runner/#use-self-managed-runners)をセットアップして、ビルド環境を完全に制御します。

Androidのビルドでは、複数のAndroid APIバージョンを提供するDockerイメージを使用します。

1. `.gitlab-ci.yml`ファイルをリポジトリのルートに作成します。
1. [Fabernovel](https://hub.docker.com/r/fabernovel/android/tags)からDockerイメージを追加します:

   ```yaml
   test:
     image: fabernovel/android:api-33-v1.7.0
     stage: test
     script:
       - fastlane test
   ```

## fastlaneとGradleでコード署名を構成する {#configure-code-signing-with-fastlane-and-gradle}

Androidのコード署名をセットアップするには、次の手順を実行します:

1. キーストアを作成します:

   1. 次のコマンドを実行してキーストアファイルを生成します:

      ```shell
      keytool -genkey -v -keystore release-keystore.jks -storepass password -alias release -keypass password \
      -keyalg RSA -keysize 2048 -validity 10000
      ```

   1. キーストア設定を`release-keystore.properties`ファイルに配置します:

      ```plaintext
      storeFile=.secure_files/release-keystore.jks
      keyAlias=release
      keyPassword=password
      storePassword=password
      ```

   1. 両方のファイルをプロジェクト設定の[セキュアファイル](../secure_files/_index.md)としてアップロードします。
   1. 両方のファイルを`.gitignore`ファイルに追加して、バージョン管理にコミットされないようにします。
1. 新しく作成したキーストアを使用するようにGradleを構成します。アプリの`build.gradle`ファイルで:

   1. [プラグイン]セクションの直後に追加します:

      ```gradle
      def keystoreProperties = new Properties()
      def keystorePropertiesFile = rootProject.file('.secure_files/release-keystore.properties')
      if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
      }
      ```

   1. `android`ブロック内の任意の場所に追加します:

      ```gradle
      signingConfigs {
        release {
          keyAlias keystoreProperties['keyAlias']
          keyPassword keystoreProperties['keyPassword']
          storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
          storePassword keystoreProperties['storePassword']
        }
      }
      ```

   1. `signingConfig`をリリースビルドタイプに追加します:

      ```gradle
      signingConfig signingConfigs.release
      ```

以下は、この設定を含む`fastlane/Fastfile`ファイルと`.gitlab-ci.yml`ファイルのサンプルです:

- `fastlane/Fastfile`: 

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Create and sign a new build"
    lane :build do
      gradle(tasks: ["clean", "assembleRelease", "bundleRelease"])
    end
  end
  ```

- `.gitlab-ci.yml`: 

  ```yaml
  build:
    image: fabernovel/android:api-33-v1.7.0
    stage: build
    script:
      - apt update -y && apt install -y curl
      - wget https://gitlab.com/gitlab-org/cli/-/releases/v1.74.0/downloads/glab_1.74.0_linux_amd64.deb
      - apt install ./glab_1.74.0_linux_amd64.deb
      - glab auth login --hostname $CI_SERVER_FQDN --job-token $CI_JOB_TOKEN
      - glab securefile download --all --output-dir .secure_files/
      - fastlane build
  ```

## Google PlayインテグレーションとfastlaneでAndroidアプリの配布をセットアップする {#set-up-android-apps-distribution-with-google-play-integration-and-fastlane}

署名付きビルドは、モバイルDevOps配信インテグレーションを使用して、Google Playストアにアップロードできます。

1. Google Cloud Platformで[Googleサービスアカウントを作成](https://docs.fastlane.tools/actions/supply/#setup)し、そのアカウントにGoogle Playのプロジェクトへのアクセス権を付与します。
1. Google Playインテグレーションを有効にします:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **設定** > **インテグレーション**を選択します。
   1. **Google Play**を選択します。
   1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
   1. **Package name**（パッケージ名）に、アプリのパッケージ名を入力します。たとえば`com.gitlab.app_name`などです。
   1. **サービスアカウントキー (.json)**で、キーファイルをドラッグまたはアップロードします。
   1. **変更を保存**を選択します。
1. リリースステップをパイプラインに追加します。

以下は、`fastlane/Fastfile`のサンプルです:

```ruby
default_platform(:android)

platform :android do
  desc "Submit a new Beta build to the Google Play store"
  lane :beta do
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab',
      release_status: 'draft'
    )
  end
end
```

以下は、`.gitlab-ci.yml`のサンプルです:

```yaml
beta:
  image: fabernovel/android:api-33-v1.7.0
  stage: beta
  script:
    - fastlane beta
```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Google Playインテグレーションのデモ](https://youtu.be/Fxaj3hna4uk)をご覧ください。

おつかれさまでした。これで、アプリは自動ビルド、署名、および配布用にセットアップされました。最初のパイプラインをトリガーするマージリクエストを作成してみてください。

## 関連トピック {#related-topics}

完全なビルド、署名、およびリリースパイプラインの例については、モバイルDevOps [Androidデモ](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/android_demo)プロジェクトを参照してください。

その他の参照資料については、GitLabブログの[DevOpsセクション](https://about.gitlab.com/blog/categories/devops/)を参照してください。
