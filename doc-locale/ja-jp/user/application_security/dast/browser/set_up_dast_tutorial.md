---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: ウェブアプリケーションをスキャンするようにDASTをセットアップする'
---

<!-- vale gitlab_base.FutureTense = NO -->

動的アプリケーションセキュリティテスト（DAST）をCI/CDパイプラインに統合する方法を学習します。

静的な解析は、ソースコード内の脆弱性を発見します。DASTは、アプリケーションが実際の環境で実行され、サービスやユーザーワークフローとやり取りするときにのみ現れるランタイムセキュリティ問題を特定します。GitLabと統合されたDASTソリューションを使用すると、テスト環境にコードをデプロイするたびに、GitLab DASTをセットアップしてこれらの問題を自動的にチェックできます。

このチュートリアルでは、次のことを学習します:

1. [Tanuki Shopアプリケーションをセットアップする](#set-up-the-tanuki-shop-application)
1. [ビルドジョブを定義する](#define-the-build-job)
1. [DASTジョブを定義する](#define-the-dast-job)
1. [パッシブスキャンとアクティブスキャンを設定する](#configure-passive-and-active-scanning)
1. [セットアップを検証する](#verify-your-setup)

> [!note]
> このチュートリアルで示すTanuki Shopアプリケーションは、認証を必要としません。アプリケーションにログインが必要な場合は、[DAST認証](../../../application_security/dast/browser/configuration/authentication.md)を参照してください。

## はじめる前 {#before-you-begin}

- GitLab Ultimateサブスクリプション。
- プロジェクトのメンテナーロール。

## Tanuki Shopアプリケーションをセットアップする {#set-up-the-tanuki-shop-application}

まずTanuki Shopをフォークすることから始めます。

1. [Tanuki Shopリポジトリ](https://gitlab.com/gitlab-da/tutorials/security-and-governance/tanuki-shop)にアクセスします。
1. 右上隅で、**フォーク**を選択します。
1. ネームスペース（個人またはグループ）を選択し、**プロジェクトをフォーク**を選択します。

   フォークしたリポジトリには、アプリケーションコードと初期CI/CD設定を含む、このチュートリアルに必要なすべてのファイルが含まれています。以下のステップで設定を変更します。

1. **設定** > **一般**にアクセスします。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **コンテナレジストリ**の切替がオンになっていることを確認してください。
1. コンテナレジストリが機能していることを確認します:
   1. **デプロイ** > **コンテナレジストリ**にアクセスします。
   1. 空のレジストリが表示されるはずです。エラーが表示される場合は、プロジェクトの権限を確認してください。

   > [!note]
   > コンテナレジストリは、パイプラインでビルドされたDockerイメージを保存します。このステップが失敗すると、ビルドジョブは後で失敗します。

## ビルドジョブを定義する {#define-the-build-job}

ここで、アプリケーションを含むDockerイメージを作成し、コンテナレジストリにプッシュするようにビルドジョブを設定します。

1. プロジェクトで、`.gitlab-ci.yml`ファイルを編集します。
1. 既存のコンテンツを次のCI/CD設定に置き換えます:

   ```yaml
   stages:
     - build
     - dast

   include:
     - template: Security/DAST.gitlab-ci.yml

   # Build: Create the Docker image and push to the container registry
   build:
     services:
       - name: docker:dind
         alias: dind
     image: docker:20.10.16
     stage: build
     script:
       - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

## DASTジョブを定義する {#define-the-dast-job}

ビルドジョブを設定したら、DASTジョブを設定します。

この設定は、サービス機能を使用して、アプリケーションコンテナをDASTジョブと並行して実行します。アプリケーションは、URL `http://yourapp:3000`の`dast`ジョブからアクセスできます。

DASTジョブを設定するには:

- `.gitlab-ci.yml`ファイルの下部に次を追加します:

  ```yaml
  # DAST: Scan the application running in a Docker container
  dast:
    services:
      - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        alias: yourapp
    variables:
      DAST_TARGET_URL: http://yourapp:3000
  ```

## パッシブスキャンとアクティブスキャンを設定する {#configure-passive-and-active-scanning}

DASTは、セキュリティカバレッジとスキャン時間のバランスをとる2つのスキャンモードをサポートしています。パッシブスキャンは迅速なフィードバックを提供します。アクティブスキャンは、アプリケーションが細工されたリクエストでテストされた場合にのみ現れる脆弱性を発見し、コードが本番環境に到達する前に、より徹底したセキュリティ検証を提供します。

パッシブスキャン（デフォルト、約2～5分）:

- 潜在的に有害なリクエストを送信せずに、アプリケーションの応答を分析します
- HTTPヘッダー、クッキー、応答コンテンツ、およびSSL/TLS設定を検査します
- あらゆる環境で安全に実行できます
- CI/CDパイプラインでの迅速なフィードバックに適しています

アクティブスキャン（アプリケーションのサイズに応じて約10～30分）:

- 脆弱性をトリガーするように設計された細工されたリクエストを送信します
- インジェクションの欠陥、認証の問題、およびビジネスロジックの脆弱性をテストします
- より徹底的ですが、速度は遅いです
- mainにマージする前のフィーチャーブランチに最適です

> [!note]
> DASTスキャンを本番環境サーバーに対して実行しないでください。ユーザーが行えるあらゆる機能（ボタンの選択やフォームの送信など）を実行できるだけでなく、バグをトリガーする可能性もあり、本番環境データの変更や損失につながる可能性があります。テストサーバーに対してのみDASTスキャンを実行してください。

パッシブスキャンとアクティブスキャンを設定するには:

- `.gitlab-ci.yml`ファイルの下部に次を追加します:

  ```yaml
    rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "false"  # Passive scan only for main branch (~2-5 mins)
      - if: $CI_COMMIT_REF_NAME != $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "true"   # Active scan for feature branches (~10-30 mins)
  ```

## セットアップを検証する {#verify-your-setup}

DASTが実行中のアプリケーションで脆弱性を正常に発見できることを確認してください。

1. パイプラインエディタで、**変更をコミットする**を選択し、`gitlab`ブランチにコミットします。

   パイプラインがすぐに開始されます。
1. **ビルド** > **パイプライン**にアクセスし、最新のパイプラインが正常に完了したことを確認します。

   予想タイムライン:
   - ビルドステージ: 2～3分（Dockerイメージの構築）
   - DASTステージ: 2～5分（パッシブスキャン）

1. パイプラインが正常に完了したら、**セキュリティ** > **脆弱性レポート**にアクセスします。
1. 脆弱性を確認してください。各脆弱性への対処方法については、[脆弱性](../../remediate/_index.md)を修正する方法を参照してください。

> [!note]
> Tanuki Shopアプリケーションは、デモンストレーション目的で意図的に脆弱性があります。セキュリティポリシー、個人を特定できる情報（PII）の露呈、その他の一般的なウェブ脆弱性に関連する発見が表示されるはずです。

## 次の手順 {#next-steps}

このチュートリアルを完了すると、次のことができるようになります:

- 特定の要件に合わせて、[高度なDAST設定](configuration/customize_settings.md)を構成できます。
- アドホックテスト用に[オンデマンドDASTスキャン](../on-demand_scan.md)を設定できます。
- DASTを[脆弱性管理ワークフロー](../../../application_security/vulnerabilities/_index.md)と統合します。
- その他の例については、[DASTデモリポジトリ](https://gitlab.com/gitlab-org/security-products/demos/dast/)を参照してください。

## トラブルシューティング {#troubleshooting}

### ビルドジョブが認証エラーで失敗する {#build-job-fails-with-authentication-errors}

認証エラーは、コンテナレジストリの認証情報が利用できない場合に発生します。

この問題を解決するには、以下の手順に従います:

1. コンテナレジストリが有効になっていることを確認します:
   1. **設定** > **一般**にアクセスします。
   1. **可視性、プロジェクトの機能、権限**を展開します。
   1. **コンテナレジストリ**の切替がオンになっていることを確認してください。

1. プロジェクトに有効なCI/CDトークンがあることを確認してください。GitLabは`$CI_REGISTRY_USER`と`$CI_REGISTRY_PASSWORD`を自動的に提供します。

### DASTジョブは完了するが脆弱性が発見されない {#dast-job-completes-but-no-vulnerabilities-are-found}

この問題は、DASTがアプリケーションに到達できない場合、またはアプリケーションに脆弱性がない場合に発生します。

この問題を解決するには、次の手順に従います:

1. アプリケーションが実行されていることを確認します:

   ```shell
   curl "http://yourapp:3000"
   ```

1. 接続に関連するエラーがないかDASTジョブログを確認してください。
1. `DAST_TARGET_URL`変数が正しく設定されていることを確認してください（`http://yourapp:3000`である必要があります）。
1. Tanuki Shopアプリケーションには脆弱性があるはずです。見つからない場合は、正しいフォークしたリポジトリを使用していることを確認してください。

## 関連トピック {#related-topics}

- [DAST設定参照](configuration/customize_settings.md)
- [セキュリティポリシー](../../../application_security/policies/_index.md)
- [脆弱性管理](../../../application_security/vulnerabilities/_index.md)
- [アプリケーションセキュリティテストソリューション](https://about.gitlab.com/solutions/application-security-testing/)
