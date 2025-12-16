---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabレジストリのトラブルシューティング
description: GitLabコンテナレジストリで発生する一般的なエラーのトラブルシューティングのヒント。
---

GitLabコンテナレジストリに関するほとんどの問題を問題を解決するには、管理者権限でGitLabにサインインする必要があります。

GitLabコンテナレジストリの管理ドキュメントで、[追加のトラブルシューティング情報](../../../administration/packages/container_registry_troubleshooting.md)を確認できます。

## OCIコンテナイメージをGitLabコンテナレジストリに移行する {#migrating-oci-container-images-to-gitlab-container-registry}

コンテナイメージをGitLabレジストリに移行することはサポートされていませんが、[エピック](https://gitlab.com/groups/gitlab-org/-/epics/5210)でこの動作の変更が提案されています。

サードパーティ製のツールを使用してコンテナイメージを移行できます。たとえば、[skopeo](https://github.com/containers/skopeo)を使用すると、さまざまなストレージメカニズム間で[コンテナイメージをコピー](https://github.com/containers/skopeo#copying-images)できます。skopeoを使用すると、コンテナレジストリ、コンテナストレージバックエンド、ローカルディレクトリ、ローカルOCIレイアウトディレクトリからGitLabコンテナレジストリにコピーできます。

## Docker接続エラー {#docker-connection-error}

グループ名、プロジェクト名、ブランチ名のいずれかに特殊文字が含まれている場合、Docker接続エラーが発生することがあります。特殊文字には以下が含まれます:

- 先頭のアンダースコア。
- 末尾のハイフンまたはダッシュ。

このエラーを解決するには、[グループパス](../../group/manage.md#change-a-groups-path) 、[プロジェクトパス](../../project/working_with_projects.md#rename-a-repository)、またはブランチ名を変更します。

Docker Engine 17.11バージョン以前を使用している場合は、`404 Not Found`または`Unknown Manifest`というエラーメッセージが表示されることがあります。現在のバージョンのDocker Engineでは、[v2 API](https://distribution.github.io/distribution/spec/manifest-v2-2/)を使用します。

GitLabコンテナレジストリ内のイメージは、Docker v2 APIを使用する必要があります。バージョン1のイメージをバージョン2にアップデートする方法については、[Dockerドキュメント](https://distribution.github.io/distribution/spec/deprecated-schema-v1/)を参照してください。

## マニフェストリストをプッシュするときの`Blob unknown to registry`エラー {#blob-unknown-to-registry-error-when-pushing-a-manifest-list}

GitLabコンテナレジストリに[Dockerマニフェストリストをプッシュする](https://docs.docker.com/reference/cli/docker/manifest/#create-and-push-a-manifest-list)と、`manifest blob unknown: blob unknown to registry`というエラーが表示されることがあります。このエラーは、複数のイメージが、同じリポジトリではなく、複数のリポジトリに分散していることが原因である可能性があります。

たとえば、それぞれがアーキテクチャを表す2つのイメージがあるとします:

- `amd64`プラットフォーム。
- `arm64v8`プラットフォーム。

これらのイメージでマルチアーキテクチャイメージをビルドするには、マルチアーキテクチャイメージと同じリポジトリにプッシュする必要があります。

`Blob unknown to registry`エラーを解決するには、個々のイメージのタグ名にアーキテクチャを含めます。たとえば、`mygroup/myapp:1.0.0-amd64`と`mygroup/myapp:1.0.0-arm64v8`を使用します。次に、マニフェストリストに`mygroup/myapp:1.0.0`でタグ付けします。

## プロジェクトパスを変更できない、またはプロジェクトを転送できない {#unable-to-change-project-path-or-transfer-a-project}

プロジェクトパスを変更するか、プロジェクトを新しいネームスペースに転送しようとすると、次のいずれかのエラーが表示されることがあります:

- タグ付けがコンテナレジストリに存在するため、プロジェクトを転送できません。
- 少なくとも1つのプロジェクトのコンテナレジストリにタグ付けがあるため、ネームスペースを移動できません。

このエラーは、プロジェクトのコンテナレジストリにイメージがある場合に発生します。パスを変更するか、プロジェクトを転送する前に、これらのイメージを削除または移動する必要があります。

次の手順では、これらのサンプルプロジェクト名を使用します:

- 現在のプロジェクトの場合: `gitlab.example.com/org/build/sample_project/cr:v2.9.1`。
- 新しいプロジェクトの場合: `gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1`。

1. コンピューターにDockerイメージをダウンロードします:

   ```shell
   docker login gitlab.example.com
   docker pull gitlab.example.com/org/build/sample_project/cr:v2.9.1
   ```

   {{< alert type="note" >}}

   認証するには、[パーソナルアクセストークン](../../profile/personal_access_tokens.md)または[デプロイトークン](../../project/deploy_tokens/_index.md)を使用してユーザーアカウントを認証します。

   {{< /alert >}}

1. 新しいプロジェクト名に合わせてイメージの名前を変更します:

   ```shell
   docker tag gitlab.example.com/org/build/sample_project/cr:v2.9.1 gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

1. [UI](delete_container_registry_images.md)または[API](../../../api/packages.md#delete-a-project-package)を使用して、古いプロジェクトのイメージを削除します。イメージがキューに入れられて削除されるまで、時間がかかる場合があります。
1. パスを変更するか、プロジェクトを転送します:

   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **設定** > **一般**を選択します。
   1. **高度な設定**セクションを展開します。
   1. **パスを変更**テキストボックスで、パスを編集します。
   1. **パスを変更**を選択します。

1. イメージを復元します:

   ```shell
   docker push gitlab.example.com/new_org/build/new_sample_project/cr:v2.9.1
   ```

詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18383)を参照してください。

## `Failed to pull image`メッセージ {#failed-to-pull-image-messages}

CI/CDジョブが、制限された[CI/CDジョブトークンスコープ](../../../ci/jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects)を持つプロジェクトからコンテナイメージをプルできない場合、[\`Failed to pull image'](../../../ci/debugging.md#failed-to-pull-image-messages)というエラーメッセージが表示されることがあります。

## エラー: `OCI manifest found, but accept header does not support OCI manifests` {#oci-manifest-found-but-accept-header-does-not-support-oci-manifests-error}

イメージをプルできない場合、レジストリログに次のようなエラーが発生する可能性があります:

```plaintext
manifest unknown: OCI manifest found, but accept header does not support OCI manifests
```

このエラーは、クライアントが正しい`Accept: application/vnd.oci.image.manifest.v1+json`ヘッダーを送信しない場合に発生します。Dockerクライアントのバージョンが最新であることを確認してください。サードパーティ製のツールを使用している場合は、OCIマニフェストを処理できることを確認してください。
