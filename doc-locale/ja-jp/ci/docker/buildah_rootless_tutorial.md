---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: OpenShift上のGitLab Runner Operatorでルートレスコンテナ内のBuildahを使用する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、OpenShiftクラスター上の[GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator)を使用してデプロイされたRunnerで、`buildah`ツールを使用してイメージを正常にビルドする方法を説明します。

このガイドは、GitLab Runner Operatorの[using Buildah to build images in aルートレスコンテナOpenShift container](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md)ドキュメントを翻案したものです。

このチュートリアルを完了する手順は、次のとおりです:

1. Buildahイメージを設定します。
1. サービスアカウントを設定します。
1. ジョブを設定します。

## はじめる前 {#before-you-begin}

このチュートリアルを完了する前に、以下があることを確認してください:

- `gitlab-runner`ネームスペースにデプロイされたRunnerがすでに存在すること。

## Buildahイメージを設定します {#configure-the-buildah-image}

`quay.io/buildah/stable:v1.23.1`イメージに基づいてカスタムイメージを準備することから始めます。

1. `Containerfile-buildah`ファイルを作成します:

   ```shell
   cat > Containerfile-buildah <<EOF
   FROM quay.io/buildah/stable:v1.23.1

   RUN touch /etc/subgid /etc/subuid \
   && chmod g=u /etc/subgid /etc/subuid /etc/passwd \
   && echo build:10000:65536 > /etc/subuid \
   && echo build:10000:65536 > /etc/subgid

   # Use chroot because the default runc does not work when running rootless
   RUN echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc

   # Use VFS because fuse does not work
   RUN mkdir -p /home/build/.config/containers \
   && (echo '[storage]';echo 'driver = "vfs"') > /home/build/.config/containers/storage.conf

   # The buildah container will run as `build` user
   USER build
   WORKDIR /home/build
   EOF
   ```

1. Buildahイメージをコンテナレジストリにビルドしてプッシュします。[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)にプッシュしましょう:

   ```shell
   docker build -f Containerfile-buildah -t registry.example.com/group/project/buildah:1.23.1 .
   docker push registry.example.com/group/project/buildah:1.23.1
   ```

## サービスアカウントを設定します {#configure-the-service-account}

これらの手順では、OpenShiftクラスターに接続されたターミナルでコマンドを実行する必要があります。

1. `buildah-sa`という名前のサービスアカウントを作成するには、このコマンドを実行します:

   ```shell
   oc create -f - <<EOF
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: buildah-sa
     namespace: gitlab-runner
   EOF
   ```

1. 作成したサービスアカウントに、`anyuid` [SCC](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html)で実行する機能を提供します:

   ```shell
   oc adm policy add-scc-to-user anyuid -z buildah-sa -n gitlab-runner
   ```

1. 新しいサービスアカウントを使用するようにOperatorを設定するには、[Runner設定テンプレート](https://docs.gitlab.com/runner/configuration/configuring_runner_operator.html#customize-configtoml-with-a-configuration-template)を使用します。以下を含む`custom-config.toml`設定ファイルを作成します:

   ```toml
   [[runners]]
     [runners.kubernetes]
         service_account_overwrite_allowed = "buildah-*"
   ```

1. `custom-config.toml`ファイルから`custom-config-toml`という名前の`ConfigMap`を作成します:

   ```shell
   oc create configmap custom-config-toml --from-file config.toml=custom-config.toml -n gitlab-runner
   ```

1. [カスタムリソース定義（CRD）ファイル](https://docs.gitlab.com/runner/install/operator.html#install-gitlab-runner)を更新して、`Runner`の`config`プロパティを設定します:

   ```yaml
   apiVersion: apps.gitlab.com/v1beta2
   kind: Runner
   metadata:
     name: buildah-runner
   spec:
     gitlabUrl: https://gitlab.example.com
     token: gitlab-runner-secret
     config: custom-config-toml
   ```

## ジョブを設定します {#configure-the-job}

最後のステップは、新しいBuildahイメージと設定されたサービスアカウントを使用するために、プロジェクトでGitLab /CI/CD設定ファイルを設定することです:

```yaml
build:
  stage: build
  image: registry.example.com/group/project/buildah:1.23.1
  variables:
    STORAGE_DRIVER: vfs
    BUILDAH_FORMAT: docker
    BUILDAH_ISOLATION: chroot
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
    KUBERNETES_SERVICE_ACCOUNT_OVERWRITE: "buildah-sa"
  before_script:
    # Log in to the GitLab container registry
    - buildah login -u "$CI_REGISTRY_USER" --password $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

ジョブは、`image`キーワードの値として、ビルドしたイメージを使用する必要があります。

`KUBERNETES_SERVICE_ACCOUNT_OVERWRITE`変数には、作成したサービスアカウント名の値を設定する必要があります。

おめでとうございます。Buildahを使用してルートレスコンテナでイメージを正常にビルドしました。

## トラブルシューティング {#troubleshooting}

非rootとして実行すると[既知のイシュー](https://github.com/containers/buildah/issues/4049)があります。OpenShift Runnerを使用している場合は、[回避策](https://docs.gitlab.com/runner/configuration/configuring_runner_operator.html#configure-setfcap)を使用する必要があるかもしれません。
