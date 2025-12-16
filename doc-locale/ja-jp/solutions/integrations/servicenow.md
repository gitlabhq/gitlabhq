---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ServiceNow
description: "ServiceNowを設定して、GitLabのワークフローを一元化し、自動化します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ServiceNowは、お客様のGitLabワークフローの管理の一元化と自動化を支援する、いくつかのインテグレーションを提供しています。

スタックを簡素化し、プロセスを合理化するために、可能な限りGitLabの[デプロイ](../../api/oauth2.md)の承認を使用する必要があります。

## GitLabスポーク {#gitlab-spoke}

ServiceNowのGitLabスポークを使用すると、GitLabプロジェクト、グループ、ユーザー、イシュー、マージリクエスト、ブランチ、リポジトリのアクションを自動化できます。

機能の完全なリストについては、[GitLabスポークのドキュメント（Xanaduリリース）](https://docs.servicenow.com/bundle/xanadu-integrate-applications/page/administer/integrationhub-store-spokes/concept/gitlab-spoke.html)を参照してください。

[GitLabをOAuth 2.0認証サービスプロバイダーとして構成する](../../integration/oauth_provider.md)必要があります。これには、アプリケーションを作成し、ServiceNowでアプリケーションIDとシークレットを提供する必要があります。

## GitLab SCMとDevOpsの継続的インテグレーション {#gitlab-scm-and-continuous-integration-for-devops}

ServiceNow DevOpsでは、GitLabリポジトリおよびGitLab CI/CDとインテグレーションして、GitLabアクティビティーと変更管理プロセスの一元的なビューを実現できます。次のことができます: 

- ServiceNowのGitLabリポジトリとCI/CDパイプラインのアクティビティーに関する情報を追跡する。
- 変更チケットの作成を自動化し、自動承認のために変更の基準を決定することにより、GitLab CI/CDパイプラインとインテグレーションします。

詳細については、次のServiceNowリソースを参照してください:

- [ServiceNow DevOpsのホームページ](https://www.servicenow.com/products/devops.html)
- [ServiceNow DevOpsドキュメント](https://docs.servicenow.com/bundle/tokyo-devops/page/product/enterprise-dev-ops/concept/dev-ops-bundle-landing-page.html)
- [GitLab SCMとDevOpsの継続的インテグレーション](https://store.servicenow.com/sn_appstore_store.do#!/store/application/54dc4eacdbc2dcd02805320b7c96191e/)
