---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オフライン設定
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または断続的な環境にあるインスタンスでは、web API fuzz testingジョブを正常に実行するために、いくつかの調整が必要です。

手順:

1. ローカルコンテナレジストリにDockerイメージをホストします。
1. `SECURE_ANALYZERS_PREFIX`をローカルコンテナレジストリに設定します。

APIファジング用のDockerイメージは、公開レジストリからプル（ダウンロード）し、ローカルレジストリにプッシュ（インポート）する必要があります。GitLabコンテナレジストリを使用して、Dockerイメージをローカルでホストできます。このプロセスは、特別なテンプレートを使用して実行できます。手順については、[Dockerイメージをオフラインホストに読み込む](../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host)を参照してください。

Dockerイメージがローカルでホストされると、`SECURE_ANALYZERS_PREFIX`変数はローカルレジストリの場所で設定されます。有効なイメージの場所になるように、`/api-security:2`を連結するように変数を設定する必要があります。

たとえば、以下の行は、イメージ`registry.gitlab.com/security-products/api-security:2`のレジストリを設定します:

`SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/security-products"`

{{< alert type="note" >}}

`SECURE_ANALYZERS_PREFIX`を設定すると、すべてのGitLabセキュアテンプレートのDockerイメージレジストリの場所が変更されます。

{{< /alert >}}

詳細については、[オフライン環境](../../offline_deployments/_index.md)を参照してください。
