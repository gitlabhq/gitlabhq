---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: macOS上でホストされるRunner
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

macOS上のホストされたRunnerは、オンデマンドのmacOS環境を提供し、GitLab [CI/CD](../../_index.md)と完全に統合されています。これらのRunnerを使用して、Appleエコシステム（macOS、iOS、watchOS、tvOS）用のアプリをビルド、テスト、およびデプロイできます。弊社の[Mobile DevOps section](../../mobile_devops/mobile_devops_tutorial_ios.md#set-up-your-build-environment)では、iOS用のモバイルアプリケーションのビルドとデプロイに関する機能、ドキュメント、およびガイダンスを提供しています。

macOS上のホストされたRunnerは[ベータ](../../../policy/development_stages_support.md#beta)版であり、オープンソースプログラム、およびPremiumプランとUltimateプランの顧客が利用できます。macOS上のホストされたRunnerの[一般公開](../../../policy/development_stages_support.md#generally-available)は、[エピック8267](https://gitlab.com/groups/gitlab-org/-/epics/8267)で提案されています。

macOS上のホストされたRunnerを使用する前に、macOS上のホストされたRunnerに影響を与える[既知の問題と使用上の制約](#known-issues-and-usage-constraints)のリストを確認してください。

## macOSで使用可能なマシンタイプ {#machine-types-available-for-macos}

GitLabは、macOS上のホストされたRunnerに対して、次のマシンタイプを提供しています。x86-64ターゲット用にビルドするには、Rosetta 2を使用してIntel x86-64環境をエミュレートできます。

| Runnerタグ               | vCPU | メモリ | ストレージ |
| ------------------------ | ----- | ------ | ------- |
| `saas-macos-medium-m1`   | 4     | 8 GB   | 50 GB   |
| `saas-macos-large-m2pro` | 6     | 16 GB  | 50 GB   |

## サポートされているmacOS Dockerイメージ {#supported-macos-images}

任意のDockerイメージを実行できるLinux上のホストされたRunnerと比較して、GitLabはmacOS用のVM Dockerイメージのセットを提供します。

`.gitlab-ci.yml`ファイルで指定する次のDockerイメージのいずれかで、ビルドを実行できます。各Dockerイメージは、macOSとXcodeの特定のバージョンを実行します。

| VM Dockerイメージ                   | ステータス       |              |
|----------------------------|--------------|--------------|
| `macos-14-xcode-15`        | `GA`         | [プリインストールされたソフトウェア](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-14-xcode-15/) |
| `macos-15-xcode-16`        | `GA`         | [プリインストールされたソフトウェア](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-15-xcode-16/) |

Dockerイメージが指定されていない場合、macOS Runnerは`macos-15-xcode-16`を使用します。

## macOSのDockerイメージアップデートポリシー {#image-update-policy-for-macos}

Dockerイメージとインストールされたコンポーネントは、プリインストールされたソフトウェアを最新の状態に保つために、GitLabの各リリースで更新されます。通常、GitLabはプリインストールされたソフトウェアの複数のバージョンをサポートしています。詳細については、[プリインストールされたソフトウェアの完全なリスト](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/tree/main/toolchain)を参照してください。

macOSとXcodeのメジャーリリースおよびマイナーリリースは、Appleリリースの次のマイルストーンで利用可能になります。

新しいメジャーリリースのDockerイメージは、最初はベータ版として利用可能になり、最初のマイナーリリースのリリースで一般公開になります。一般公開されているDockerイメージは一度に2つしかサポートされていないため、最も古いDockerイメージは非推奨となり、[サポートされているDockerイメージのライフサイクル](_index.md#supported-image-lifecycle)に従って3か月後に削除されます。

新しいメジャーリリースが一般公開されると、すべてのmacOSジョブのデフォルトのDockerイメージになります。

## `.gitlab-ci.yml`ファイルの例 {#example-gitlab-ciyml-file}

次のサンプルの`.gitlab-ci.yml`ファイルは、macOS上のホストされたRunnerの使用を開始する方法を示しています。: 

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-14-xcode-15
  before_script:
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .macos_saas_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .macos_saas_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

## fastlaneを使用したiOSプロジェクトのコード署名 {#code-signing-ios-projects-with-fastlane}

GitLabをAppleサービスと統合したり、デバイスにインストールしたり、Apple App Storeにデプロイしたりする前に、アプリケーションに[コード署名](https://developer.apple.com/documentation/security/code_signing_services)する必要があります。

macOS VM Dockerイメージの各Runnerには、モバイルアプリのデプロイの簡素化を目的としたオープンソースソリューションである[fastlane](https://fastlane.tools/)が含まれています。

アプリケーションのコード署名を設定する方法については、[Mobile DevOps documentation](../../mobile_devops/mobile_devops_tutorial_ios.md#configure-code-signing-with-fastlane)の手順を参照してください。

関連トピック: 

- [Apple Developer Support - コード署名](https://forums.developer.apple.com/forums/thread/707080)
- [コード署名のベストプラクティスガイド](https://codesigning.guide/)
- [fastlane authentication with Apple Services guide](https://docs.fastlane.tools/getting-started/ios/authentication/)

## Homebrewの最適化 {#optimizing-homebrew}

デフォルトでは、Homebrewは操作の開始時に更新を確認します。Homebrewには、GitLab macOS Dockerイメージのリリースサイクルよりも頻繁なリリースサイクルがあります。このリリースサイクルの違いにより、Homebrewが更新を行う間、`brew`を呼び出す手順の完了に時間がかかる場合があります。

意図しないHomebrewの更新によるビルド時間を短縮するには、`HOMEBREW_NO_AUTO_UPDATE`変数を`.gitlab-ci.yml`に設定します。: 

```yaml
variables:
  HOMEBREW_NO_AUTO_UPDATE: 1
```

## Cocoapodsの最適化 {#optimizing-cocoapods}

プロジェクトでCocoapodsを使用する場合は、CIパフォーマンスを向上させるために、次の最適化を検討する必要があります。

**Cocoapods CDN**

コンテンツ配信ネットワーク（CDN）アクセスを使用して、プロジェクトリポジトリ全体を複製する代わりに、CDNからパッケージをダウンロードできます。CDNアクセスはCocoapods 1.8以降で使用でき、macOS上のすべてのGitLabホストされたRunnerでサポートされています。

CDNアクセスを有効にするには、Podfileが次で始まるようにしてください。: 

```ruby
source 'https://cdn.cocoapods.org/'
```

**GitLabキャッシュの使用**

GitLabのCocoapodsパッケージでキャッシュを使用すると、podが変更された場合にのみ`pod install`を実行できるため、ビルドのパフォーマンスが向上します。

プロジェクトの[キャッシュを設定](../../caching/_index.md)するには：: 

1. `cache`設定を`.gitlab-ci.yml`ファイルに追加します。: 

   ```yaml
   cache:
     key:
       files:
        - Podfile.lock
   paths:
     - Pods
   ```

1. [`cocoapods-check`](https://guides.cocoapods.org/plugins/optimising-ci-times.html)プラグインをプロジェクトに追加します。
1. `pod install`を呼び出す前に、インストールされている依存を確認するようにジョブスクリプトを更新します。: 

   ```shell
   bundle exec pod check || bundle exec pod install
   ```

**ソース管理にポッドを含める**

[ソース管理にポッドディレクトリを含める](https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control)こともできます。これにより、CIジョブの一部としてポッドをインストールする必要がなくなりますが、プロジェクトのリポジトリ全体のサイズが大きくなります。

## 既知の問題と使用上の制約 {#known-issues-and-usage-constraints}

- VM Dockerイメージにジョブに必要な特定のソフトウェアバージョンが含まれていない場合は、必要なソフトウェアをフェッチしてインストールする必要があります。これにより、ジョブの実行時間が長くなります。
- 独自のOS Dockerイメージを持ち込むことはできません。
- ユーザー`gitlab`のキーチェーンは公開されていません。代わりにキーチェーンを作成する必要があります。
- macOS上のホストされたRunnerは、ヘッドレスモードで実行されます。`testmanagerd`などのUIインタラクションを必要とするワークロードはサポートされていません。
- Appleシリコンチップには効率性とパフォーマンスコアがあるため、ジョブの実行パフォーマンスはジョブの実行間で異なる場合があります。コアの割り当てまたはスケジュールを制御できないため、不整合が発生する可能性があります。
- macOS上のホストされたRunnerに使用されるAWSベアメタルmacOSマシンの可用性は限られています。マシンが利用できない場合、ジョブのキュー時間が長くなる可能性があります。
- macOS上のホストされたRunnerインスタンスがリクエストに応答しない場合があり、その結果、ジョブの最大継続時間に達するまでジョブがハングアップします。
