---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: macOS上のホストRunner
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

macOS上のHosted Runnerは、オンデマンドのmacOS環境を提供し、GitLab [CI/CD](../../_index.md)と完全に統合されています。これらのRunnerを使用して、Appleエコシステム（macOS、iOS、watchOS、tvOS）向けにアプリをビルド、テスト、およびデプロイできます。当社の[Mobile DevOpsセクション](../../mobile_devops/mobile_devops_tutorial_ios.md#set-up-your-build-environment)では、iOS向けモバイルアプリケーションのビルドとデプロイに関する機能、ドキュメント、およびガイダンスを提供しています。

macOS上のHosted Runnerは[ベータ](../../../policy/development_stages_support.md#beta)版であり、オープンソースプログラムとPremiumおよびUltimateプランのお客様にご利用いただけます。macOS上のHosted Runnerの[一般公開](../../../policy/development_stages_support.md#generally-available)は、[エピック8267](https://gitlab.com/groups/gitlab-org/-/epics/8267)で提案されています。

使用する前に、macOS上のHosted Runnerに影響する[既知のイシューと使用上の制約](#known-issues-and-usage-constraints)のリストを確認してください。

## macOSで利用可能なマシンタイプ {#machine-types-available-for-macos}

GitLabは、macOS上のHosted Runner向けに以下のマシンタイプを提供しています。x86-64ターゲット向けにビルドするには、Rosetta 2を使用してIntel x86-64環境をエミュレートできます。

| Runnerタグ               | vCPU | メモリ | ストレージ |
| ------------------------ | ----- | ------ | ------- |
| `saas-macos-medium-m1`   | 4     | 8 GB   | 50 GB   |
| `saas-macos-large-m2pro` | 6     | 16 GB  | 50 GB   |

## サポートされているmacOSイメージ {#supported-macos-images}

Linux上のHosted Runnerで任意のDockerイメージを実行できるのと比較して、GitLabはmacOS向けに一連のVMイメージを提供しています。

次のいずれかのイメージでビルドを実行でき、そのイメージは`.gitlab-ci.yml`ファイルで指定します。各イメージは、macOSとXcodeの特定のバージョンを実行します。

| VMイメージ                   | ステータス       |              |
|----------------------------|--------------|--------------|
| `macos-14-xcode-15`        | `deprecated` | [プリインストールされたソフトウェア](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-14-xcode-15/) |
| `macos-15-xcode-16`        | `GA`         | [プリインストールされたソフトウェア](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-15-xcode-16/) |
| `macos-26-xcode-26`        | `GA`         | [プリインストールされたソフトウェア](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-26-xcode-26/) |

イメージが指定されていない場合、macOS Runnerは`macos-15-xcode-16`を使用します。

## macOSのイメージ更新ポリシー {#image-update-policy-for-macos}

イメージとインストールされているコンポーネントは、プリインストールされているソフトウェアを最新の状態に保つため、各GitLabリリースで更新されます。GitLabは通常、プリインストールされたソフトウェアの複数のバージョンをサポートしています。詳細については、[プリインストールされたソフトウェアの完全なリスト](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/tree/main/toolchain)を参照してください。

macOSとXcodeのメジャーリリースおよびマイナーリリースは、Appleリリース後のマイルストーンで利用可能になります。

新しいメジャーリリースイメージは、最初にベータ版として利用可能になり、最初のマイナーリリースのリリースに伴って一般公開されます。一度に2つの一般公開イメージのみがサポートされるため、最も古いイメージは非推奨となり、[サポートされるイメージライフサイクル](_index.md#supported-image-lifecycle)に従って3か月後に削除されます。

新しいメジャーリリースが一般公開されると、それはすべてのmacOSジョブのデフォルトイメージになります。

## `.gitlab-ci.yml`ファイルの例 {#example-gitlab-ciyml-file}

以下のサンプル`.gitlab-ci.yml`ファイルは、macOS上でHosted Runnerを使い始める方法を示しています:

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

AppleサービスとGitLabを統合したり、デバイスにインストールしたり、Apple App Storeにデプロイしたりする前に、アプリケーションを[コード署名](https://developer.apple.com/documentation/security/code_signing_services)する必要があります。

macOS VMイメージの各Runnerには、モバイルアプリのデプロイを簡素化することを目的としたオープンソースソリューションである[fastlane](https://fastlane.tools/)が含まれています。

アプリケーションのコード署名を設定する方法については、[Mobile DevOpsドキュメント](../../mobile_devops/mobile_devops_tutorial_ios.md#configure-code-signing-with-fastlane)の指示を参照してください。

関連トピック:

- [Apple Developer Support - コード署名](https://forums.developer.apple.com/forums/thread/707080)
- [コード署名のベストプラクティスガイド](https://codesigning.guide/)
- [fastlaneとAppleサービスによる認証ガイド](https://docs.fastlane.tools/getting-started/ios/authentication/)

## Homebrewの最適化 {#optimizing-homebrew}

デフォルトで、Homebrewは任意の操作の開始時に更新をチェックします。Homebrewのリリースサイクルは、GitLab macOSイメージのリリースサイクルよりも頻繁である場合があります。このリリースサイクルの違いにより、Homebrewが更新を行う際に`brew`を呼び出す手順に余分な時間がかかる場合があります。

意図しないHomebrewの更新によるビルド時間を短縮するには、`.gitlab-ci.yml`で`HOMEBREW_NO_AUTO_UPDATE`変数を設定します:

```yaml
variables:
  HOMEBREW_NO_AUTO_UPDATE: 1
```

## CocoaPodsの最適化 {#optimizing-cocoapods}

プロジェクトでCocoaPodsを使用する場合、CIのパフォーマンスを向上させるために以下の最適化を検討してください。

**CocoaPods CDN**

コンテンツデリバリーネットワーク（CDN）アクセスを使用して、プロジェクトリポジトリ全体をクローンする代わりに、CDNからパッケージをダウンロードできます。CDNアクセスはCocoaPods 1.8以降で利用可能であり、macOS上のすべてのGitLab Hosted Runnerでサポートされています。

CDNアクセスを有効にするには、Podfileが次から始まることを確認してください:

```ruby
source 'https://cdn.cocoapods.org/'
```

**Use GitLab caching**

GitLabのCocoaPodsパッケージでキャッシュを使用すると、ポッドが変更されたときにのみ`pod install`を実行でき、ビルドパフォーマンスを向上させることができます。

プロジェクトの[キャッシュを構成](../../caching/_index.md)するには:

1. `.gitlab-ci.yml`ファイルに`cache`設定を追加します:

   ```yaml
   cache:
     key:
       files:
        - Podfile.lock
   paths:
     - Pods
   ```

1. プロジェクトに[`cocoapods-check`](https://guides.cocoapods.org/plugins/optimising-ci-times.html)プラグインを追加します。
1. `pod install`を呼び出す前に、インストールされている依存関係をチェックするようにジョブスクリプトを更新します:

   ```shell
   bundle exec pod check || bundle exec pod install
   ```

**Include pods in source control**

ポッドディレクトリを[ソース管理に含める](https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control)こともできます。これにより、CIジョブの一部としてポッドをインストールする必要がなくなりますが、プロジェクトのリポジトリの全体的なサイズは増加します。

## 既知のイシューと使用上の制約 {#known-issues-and-usage-constraints}

- VMイメージにジョブに必要な特定のソフトウェアバージョンが含まれていない場合、必要なソフトウェアをフェッチしてインストールする必要があります。これにより、ジョブの実行時間が増加します。
- 独自のOSイメージを持ち込むことはできません。
- ユーザー`gitlab`のキーチェーンは一般公開されていません。代わりにキーチェーンを作成する必要があります。
- macOS上のHosted Runnerはヘッドレスモードで実行されます。`testmanagerd`などのUIインタラクションを必要とするすべてのワークロードはサポートされていません。
- Appleシリコンチップには効率性コアとパフォーマンスコアがあるため、ジョブの実行間でジョブのパフォーマンスが異なる場合があります。コアの割り当てやスケジューリングを制御することはできず、これにより一貫性が失われる可能性があります。
- macOS上のHosted Runnerに使用されるAWSベアメタルmacOSマシンの可用性は限られています。マシンが利用できない場合、ジョブのキューイング時間が長くなる可能性があります。
- macOS上のHosted Runnerインスタンスは、リクエストに応答しないことがあり、その結果、最大ジョブ期間に達するまでジョブがハングアップすることがあります。
- macOSはデフォルトで大文字と小文字を区別しないファイルシステムを使用します。この動作は、大文字と小文字を除いて同じファイルパスの重複がある場合に、予期せぬエラーを引き起こす可能性があります。これらの重複したパスは、Gitワークツリー、またはブランチとタグが保存されているGit refsに存在する可能性があります。
