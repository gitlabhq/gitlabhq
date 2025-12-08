---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アプリケーションデプロイのオプション
---

DASTでは、スキャンを実行するために、デプロイされたアプリケーションが利用可能である必要があります。

ターゲット・アプリケーションの複雑さに応じて、DASTテンプレートをデプロイして設定する方法がいくつかあります。サンプル・アプリケーションのセットが、[DAST demonstrations](https://gitlab.com/gitlab-org/security-products/demos/dast/)プロジェクトの設定とともに提供されています。

## レビューアプリ {#review-apps}

レビューアプリは、DASTターゲット・アプリケーションをデプロイするための最も手間のかかる方法です。そのプロセスを支援するために、GitLabはGoogle Kubernetes Engine (GKE) を使用してレビューアプリのデプロイを作成しました。この例は、[Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke)プロジェクトにあります。また、DASTのレビューアプリを設定するための詳細な手順は[README](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)にあります。

## Docker Services {#docker-services}

アプリケーションでDockerコンテナを使用している場合は、DASTを使用してデプロイおよびスキャンを行うための別のオプションがあります。Dockerのビルドジョブが完了し、イメージがコンテナレジストリに追加されたら、イメージを[サービス](../../../../ci/services/_index.md)として使用できます。

`.gitlab-ci.yml`でサービス定義を使用することにより、DASTアナライザーでサービスをスキャンできます。

ジョブに`services`セクションを追加すると、サービスへのアクセスに使用できるホスト名を定義するために`alias`が使用されます。次の例では、`dast`ジョブ定義の`alias: yourapp`部分は、デプロイされたアプリケーションへのURLがホスト名として`yourapp` (`https://yourapp/`) を使用することを意味します。

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
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

dast:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  DAST_TARGET_URL: https://yourapp
  DAST_FULL_SCAN: "true" # do a full scan
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

ほとんどのアプリケーションは、データベースやキャッシュサービスなどの複数のサービスに依存しています。デフォルトでは、servicesフィールドで定義されたサービスは互いに通信できません。サービス間の通信を許可するには、`FF_NETWORK_PER_BUILD` [機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)を有効にします。

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```
