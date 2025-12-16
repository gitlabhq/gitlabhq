---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリからコンテナイメージを削除する
description: GitLabでコンテナイメージを削除するための自動および手動による方法。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナイメージをレジストリから削除できます。

特定の条件に基づいてコンテナイメージを自動的に削除するには、[ガベージコレクション](#garbage-collection)を使用します。または、サードパーティ製のツールを使用して、特定のプロジェクトからコンテナイメージを削除するための[CI/CDジョブ](#use-gitlab-cicd)を作成できます。

プロジェクトまたはグループから特定のコンテナイメージを削除するには、[GitLab UI](#use-the-gitlab-ui)または[GitLab API](#use-the-gitlab-api)を使用します。

{{< alert type="warning" >}}

コンテナイメージの削除は破壊的な操作であり、元に戻すことはできません。削除されたコンテナイメージを復元するには、ビルドして再度アップロードする必要があります。

{{< /alert >}}

## ガベージコレクション {#garbage-collection}

GitLab Self-Managedインスタンスでコンテナイメージを削除しても、ストレージ容量は解放されず、削除対象としてマークされるだけです。参照されていないコンテナイメージを実際に削除してストレージ容量を回復するには、GitLab Self-Managedインスタンスの管理者が[ガベージコレクション](../../../administration/packages/container_registry.md#container-registry-garbage-collection)を実行する必要があります。

GitLab.comのコンテナレジストリには、自動オンラインガベージコレクターが含まれています。自動ガベージコレクターを使用すると、参照されていない場合、以下は24時間後に自動的に削除がスケジュールされます:

- どのイメージマニフェストにも参照されていないレイヤー。
- タグ付けされておらず、別のマニフェスト（マルチアーキテクチャイメージなど）によって参照されていないイメージマニフェスト。

オンラインガベージコレクターはインスタンス全体の機能であり、すべてのネームスペースに適用されます。

## GitLab UIを使用する {#use-the-gitlab-ui}

GitLab UIを使用してコンテナイメージを削除するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 詳細は以下の説明を参照してください:
   - グループの場合は、**操作** > **Container Registry**（コンテナレジストリ）を選択します。
   - プロジェクトの場合は、**デプロイ** > **Container Registry**（コンテナレジストリ）を選択します。
1. **Container Registry**（コンテナレジストリ）ページから、次のいずれかの方法で削除するものを選択できます:

   - 赤い{{< icon name="remove" >}} **Trash**アイコンを選択して、リポジトリ全体と、それに含まれるすべてのタグ付けを削除します。
   - リポジトリに移動し、赤い{{< icon name="remove" >}} **Trash**アイコンを削除するタグの横にあるアイコンを選択して、タグ付けを個別にまたはまとめて削除します。

1. ダイアログで、**タグを削除**を選択します。

[削除に10回以上失敗した](../../../administration/packages/container_registry.md#max-retries-for-deleting-container-images)コンテナリポジトリは、自動的にイメージの削除を停止します。

## GitLab APIを使用する {#use-the-gitlab-api}

APIを使用して、コンテナイメージの削除プロセスを自動化できます。詳細については、次のエンドポイントを参照してください:

- [レジストリリポジトリを削除する](../../../api/container_registry.md#delete-registry-repository)
- [個々のレジストリリポジトリタグを削除](../../../api/container_registry.md#delete-a-registry-repository-tag)
- [レジストリリポジトリのタグを一括削除する](../../../api/container_registry.md#delete-registry-repository-tags-in-bulk)

## GitLab CI/CDを使用する {#use-gitlab-cicd}

{{< alert type="note" >}}

GitLab CI/CDには、コンテナイメージを削除する組み込みの方法はありません。この例では、GitLabレジストリAPIと通信する[`regctl`](https://github.com/regclient/regclient)というサードパーティ製のツールを使用しています。このサードパーティ製ツールのサポートについては、[regclientのイシュートラッカー](https://github.com/regclient/regclient/issues)を参照してください。

{{< /alert >}}

次の例では、2つのステージング、`build`と`clean`を定義します。`build_image`ジョブはブランチのコンテナイメージをビルドし、`delete_image`ジョブはそれを削除します。`reg`実行可能ファイルがダウンロードされ、`$CI_PROJECT_PATH:$CI_COMMIT_REF_SLUG` [定義済みのCI/CD変数](../../../ci/variables/predefined_variables.md)に一致するコンテナイメージを削除するために使用されます。

この例を使用するには、ニーズに合わせて`IMAGE_TAG`変数を変更します。

```yaml
stages:
  - build
  - clean

build_image:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
  rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
        when: never
      - if: $CI_COMMIT_BRANCH

delete_image:
  stage: clean
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
    REGCTL_VERSION: v0.6.1
  rules:
      - if: $CI_COMMIT_REF_NAME != $CI_DEFAULT_BRANCH
  image: alpine:latest
  script:
    - apk update
    - apk add curl
    - curl --fail-with-body --location "https://github.com/regclient/regclient/releases/download/${REGCTL_VERSION}/regctl-linux-amd64" > /usr/bin/regctl
    - chmod 755 /usr/bin/regctl
    - regctl registry login ${CI_REGISTRY} -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD}
    - regctl tag rm $IMAGE
```

{{< alert type="note" >}}

[リリース](https://github.com/regclient/regclient/releasess)ページから最新の`regctl`リリースをダウンロードし、`delete_image`ジョブで定義されている`REGCTL_VERSION`変数を変更してコード例を更新できます。

{{< /alert >}}

## クリーンアップポリシーを使用する {#use-a-cleanup-policy}

プロジェクトごとの[クリーンアップポリシー](reduce_container_registry_storage.md#cleanup-policy)を作成して、古いタグとイメージがコンテナレジストリから定期的に削除されるようにすることができます。
