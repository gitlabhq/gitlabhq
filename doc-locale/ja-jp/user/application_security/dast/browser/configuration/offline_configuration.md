---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オフライン設定
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由で外部リソースへのアクセスが制限されている、または不安定な環境にあるインスタンスでは、DASTジョブを正常に実行するためにいくつかの調整が必要です。詳細については、[オフライン環境](../../../offline_deployments/_index.md)を参照してください。

## オフラインDASTサポートの要件 {#requirements-for-offline-dast-support}

オフライン環境では、どのバージョンのDASTも使用できます。これを行うには、以下が必要です:

- [`docker`または`kubernetes` executor](../_index.md)を備えたGitLab Runner。Runnerは、ターゲットアプリケーションへのネットワークアクセス権を持っている必要があります。
- DAST [コンテナイメージ](https://gitlab.com/security-products/dast)のローカルで利用可能なコピーを含むDockerコンテナレジストリ（[DASTコンテナレジストリ](https://gitlab.com/security-products/dast/container_registry)にあります）。[オフラインホストへのDockerイメージのロード](../../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host)を参照してください。

GitLab Runnerでは、[デフォルトで`pull policy`が`always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy)になっています。つまり、ローカルコピーが利用可能な場合でも、RunnerはGitLabコンテナレジストリからDockerイメージをプルしようとします。オフライン環境ではローカルで利用可能なDockerイメージのみを使用する場合は、GitLab Runnerの[`pull_policy`を`if-not-present`に設定できます](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)。ただし、オフライン環境でない場合は、プルポリシーの設定を`always`のままにしておくことをおすすめします。これにより、CI/CDパイプラインで常に最新のスキャナーを使用できるようになります。

## Dockerレジストリ内でGitLab DASTアナライザーイメージを利用できるようにする {#make-gitlab-dast-analyzer-images-available-inside-your-docker-registry}

DASTの場合は、次のデフォルトのDASTアナライザーイメージを`registry.gitlab.com`から[ローカルDockerコンテナレジストリ](../../../../packages/container_registry/_index.md)にインポートします:

- `registry.gitlab.com/security-products/dast:latest`

DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**your network security policy**（ネットワークのセキュリティポリシー）によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは新しい定義で[定期的に更新](../../../detect/vulnerability_scanner_maintenance.md)されています。また、自分で随時更新できる場合もあります。

Dockerイメージをファイルとして保存および転送する方法の詳細については、[`docker save`](https://docs.docker.com/reference/cli/docker/image/save/) 、[`docker load`](https://docs.docker.com/reference/cli/docker/image/load/) 、[`docker export`](https://docs.docker.com/reference/cli/docker/container/export/) 、[`docker import`](https://docs.docker.com/reference/cli/docker/image/import/)に関するDockerのドキュメントを参照してください。

## ローカルDASTアナライザーを使用するようにDAST CI/CDジョブ変数を設定する {#set-dast-cicd-job-variables-to-use-local-dast-analyzers}

次の設定を`.gitlab-ci.yml`ファイルに追加します。`image`を、ローカルDockerコンテナレジストリでホストされているDAST Dockerイメージを参照するように置き換える必要があります:

```yaml
include:
  - template: DAST.gitlab-ci.yml
dast:
  image: registry.example.com/namespace/dast:latest
```

この設定により、DASTジョブは、インターネットアクセスを必要とせずに、DASTアナライザーのローカルコピーを使用してコードをスキャンし、セキュリティレポートを生成できるようになります。

または、CI/CD変数`SECURE_ANALYZERS_PREFIX`を使用して、`dast`イメージのベースレジストリアドレスをオーバーライドできます。
