---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プロジェクト、イシュー、認証、セキュリティプロバイダー
title: GitLabとの連携
---

GitLabは、機能拡張のために外部アプリケーションと連携できます。

## プロジェクトインテグレーション {#project-integrations}

Jenkins、Jira、Slackなどのアプリケーションは、[プロジェクトインテグレーション](../user/project/integrations/_index.md)として利用できます。

## イシュートラッカー {#issue-trackers}

[外部イシュートラッカー](external-issue-tracker.md)を設定して、以下を使用できます:

- 外部イシュートラッカーとGitLabイシュートラッカー
- 外部イシュートラッカーのみ

## 認証プロバイダー {#authentication-providers}

GitLabをLDAPやSAMLなどの認証プロバイダーと連携させることができます。

詳細については、[GitLabの認証と認可](../administration/auth/_index.md)を参照してください。

## セキュリティの改善 {#security-improvements}

AkismetやreCAPTCHAなどのソリューションをスパム対策に利用できます。

また、GitLabは、以下のセキュリティパートナーと連携できます:

<!-- vale gitlab_base.Spelling = NO -->

- [Anchore](https://docs.anchore.com/current/docs/integration/ci_cd/gitlab/)
- [Prisma Cloud](https://docs.prismacloud.io/en/enterprise-edition/content-collections/application-security/get-started/connect-code-and-build-providers/code-repositories/add-gitlab)
- [Checkmarx](https://checkmarx.atlassian.net/wiki/spaces/SD/pages/1929937052/GitLab+Integration)
- [CodeSecure](https://codesecure.com/our-integrations/codesonar-sast-gitlab-ci-pipeline/)
- [Deepfactor](https://www.deepfactor.io/docs/integrate-deepfactor-scanner-in-your-ci-cd-pipelines/#gitlab)
- [Fortify](https://www.microfocus.com/en-us/fortify-integrations/gitlab)
- [Indeni](https://docs.cloudrail.app/#/integrations/gitlab)
- [Jscrambler](https://docs.jscrambler.com/code-integrity/documentation/gitlab-ci-integration)
- [Mend](https://www.mend.io/gitlab/)
- [Semgrep](https://semgrep.dev/for/gitlab/)
- [StackHawk](https://docs.stackhawk.com/continuous-integration/gitlab/)
- [Tenable](https://docs.tenable.com/vulnerability-management/Content/vulnerability-management/VulnerabilityManagementOverview.htm)
- [Venafi](https://marketplace.venafi.com/xchange/620d2d6ed419fb06a5c5bd36/solution/6292c2ef7550f2ee553cf223)
- [Veracode](https://docs.veracode.com/r/c_integration_buildservs#gitlab)

<!-- vale gitlab_base.Spelling = YES -->

GitLabは、セキュリティの脆弱性に関してアプリケーションをチェックできます。詳細については、[アプリケーションを保護する](../user/application_security/secure_your_application.md)を参照してください。

## トラブルシューティング {#troubleshooting}

インテグレーションを使用する場合、以下の問題が発生することがあります。

### SSL証明書エラー {#ssl-certificate-errors}

自己署名証明書を使用してGitLabと外部アプリケーションを連携させると、GitLabのさまざまな部分でSSL証明書エラーが発生することがあります。

回避策として、次のいずれかを実行してください:

- OSが信頼できるチェーンに証明書を追加します。詳細については、以下を参照してください:
  - [Adding trusted root certificates to the server](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)（信頼されたルート証明書をサーバーに追加する）
  - [How do you add a certificate authority (CA) to Ubuntu?](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)（Ubuntuに認証局（CA）を追加する方法）
- Linuxパッケージを使用するインストールの場合、GitLabが信頼できるチェーンに証明書を追加します:
  1. [自己署名証明書をインストールします](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)。
  1. 自己署名証明書を、GitLabが信頼できる証明書と連結します。自己署名証明書は、アップグレード中に上書きされる可能性があります。

     ```shell
     cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
     ```

  1. GitLabを再起動します。

     ```shell
     sudo gitlab-ctl restart
     ```

### KibanaでSidekiqログを検索する {#search-sidekiq-logs-in-kibana}

Kibanaで特定のインテグレーションを見つけるには、次のKQL検索文字列を使用します:

```plaintext
`json.integration_class.keyword : "Integrations::Jira" and json.project_path : "path/to/project"`
```

以下で情報を見つけることができます:

- `json.exception.backtrace`
- `json.exception.class`
- `json.exception.message`
- `json.message`

### エラー: `Test Failed. Save Anyway` {#error-test-failed-save-anyway}

初期化されていないリポジトリでインテグレーションを設定すると、`Test Failed. Save Anyway`エラーが発生し、インテグレーションが失敗する場合があります。プロジェクトにプッシュイベントがない場合、インテグレーションがプッシュデータを使用してテストペイロードを作成するため、このエラーが発生します。

この問題を解決するには、テストファイルをプロジェクトにプッシュしてリポジトリを初期化してから、インテグレーションを再度設定してください。
