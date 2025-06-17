---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインストール後の手順
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インストール完了後に確認するとよいリソースをいくつかご紹介します。

## メールと通知

- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html): 適切なメール通知をサポートするためにSMTPを設定します。
- [受信メール](../administration/incoming_email.md): ユーザーがメールを使用してコメントへの返信、新しいイシューとマージリクエストの作成などを行えるように、受信メールを設定します。

## CI/CD (Runner)

- [Runnerのセットアップ](https://docs.gitlab.com/runner/): CI/CDジョブの実行を担当するエージェントであるRunnerを1つ以上設定します。

## コンテナレジストリ

- [コンテナレジストリ](../administration/packages/container_registry.md): 各GitLabプロジェクトのコンテナイメージを保存するための統合コンテナレジストリ
- [GitLab依存プロキシ](../administration/packages/dependency_proxy.md): より高速で信頼性の高いビルドのために、Docker Hubからコンテナイメージをキャッシュできるよう、依存プロキシを設定します。

## Pages

- [GitLab Pages](../user/project/pages/_index.md): 静的ウェブサイトをGitLabのリポジトリから直接公開します。

## セキュリティ

- [GitLabのセキュリティ保護](../security/_index.md): GitLabインスタンスをセキュリティ保護するための推奨プラクティスです。
- GitLab[セキュリティニュースレター](https://about.gitlab.com/company/preference-center/)にサインアップして、リリース時のセキュリティアップデートの通知を受け取ります。

## 認証

- [LDAP](../administration/auth/ldap/_index.md): GitLabの認証メカニズムとして使用されるLDAPを設定します。
- [SAMLとOAuth](../integration/omniauth.md): Okta、Google、Azure ADなどのオンラインサービス経由で認証します。

## バックアップとアップグレード

- [GitLabのバックアップと復元](../administration/backup_restore/_index.md): GitLabをバックアップまたは復元できるさまざまな方法について説明します。
- [GitLabのアップグレード](../update/_index.md): 毎月、新機能が豊富なGitLabバージョンがリリースされます。そのバージョンまたはセキュリティ修正を含む暫定リリースにアップグレードする方法について説明します。
- [リリースおよびメンテナンスポリシー](../policy/maintenance.md): バージョン命名規則、およびメジャー、マイナー、パッチリリースに関するGitLabポリシーについて説明します。

## ライセンス

- [ライセンスの追加](../administration/license.md)または[無料トライアルの開始](https://about.gitlab.com/free-trial/): ライセンスを使用して、すべてのGitLab Enterpriseエディションの機能を有効にします。
- [価格](https://about.gitlab.com/pricing/): さまざまなプランの料金を確認できます。

## クロスリポジトリコード検索

- [高度な検索](../integration/advanced_search/elasticsearch.md): GitLabインスタンス全体で、より高速で高度なコード検索を行うには、[Elasticsearch](https://www.elastic.co/)または[OpenSearch](https://opensearch.org/)を活用してください。

## スケーリングとレプリケーション

- [GitLabのスケーリング](../administration/reference_architectures/_index.md): GitLabは、いくつかの異なるタイプのクラスタリングをサポートしています。
- [Geoレプリケーション](../administration/geo/_index.md): Geoは、広範な分散型開発チーム向けのソリューションです。

## 製品ドキュメントをインストールする

（オプション）ドキュメントを独自のサーバーでホストする場合は、[製品ドキュメントをセルフホスティング](../administration/docs_self_host.md)する方法を参照してください。
