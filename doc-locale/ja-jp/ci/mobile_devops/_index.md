---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mobile DevOps
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDを使用して、AndroidおよびiOS用のネイティブおよびクロスプラットフォームのモバイルアプリをビルド、署名、リリースします。GitLab Mobile DevOpsは、モバイルアプリ開発ワークフローを自動化するためのツールとベストプラクティスを提供します。

GitLab Mobile DevOpsは、主要なモバイル開発機能をDevSecOpsプラットフォームに統合します:

- iOSおよびAndroid開発用のビルド環境
- セキュアなコード署名と証明書管理
- Google PlayおよびApple App Storeのアプリストアディストリビューション

## ビルド環境 {#build-environments}

ビルド環境を完全に制御するには、[GitLabホストされたRunner](../runners/_index.md)を使用するか、[セルフマネージドRunner](https://docs.gitlab.com/runner/#use-self-managed-runners)をセットアップします。

## コード署名 {#code-signing}

すべてのAndroidおよびiOSアプリは、さまざまなアプリストアを通じて配布する前に、安全に署名されている必要があります。署名により、アプリケーションがユーザーのデバイスに到達する前に改ざんされていないことが保証されます。

[プロジェクトレベルのセキュアファイル](../secure_files/_index.md)を使用すると、次のものをGitLabに保存して、CI/CDビルドでアプリを安全に署名するために使用できます:

- キーストア
- プロビジョニングプロファイル
- 署名証明書

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[プロジェクトレベルのセキュアファイルのデモ](https://youtu.be/O7FbJu3H2YM)を参照してください。

## ディストリビューション {#distribution}

署名付きビルドは、Mobile DevOpsインテグレーションを使用して、Google PlayストアまたはApple App Storeにアップロードできます。

## 関連トピック {#related-topics}

Mobile DevOpsの実装に関するステップごとのガイダンスについては、以下を参照してください:

- [チュートリアル: GitLab Mobile DevOpsでAndroidアプリをビルドする](mobile_devops_tutorial_android.md)
- [チュートリアル: GitLab Mobile DevOpsでiOSアプリをビルドする](mobile_devops_tutorial_ios.md)
