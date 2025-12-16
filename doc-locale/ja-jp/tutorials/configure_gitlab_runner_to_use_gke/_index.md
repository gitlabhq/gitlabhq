---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Google Kubernetes Engineを使用するようにGitLab Runnerを設定する'
---

このチュートリアルでは、GitLab RunnerをGoogle Kubernetes Engine（GKE）で使用するように設定し、ジョブを実行する方法について説明します。

このチュートリアルでは、GitLab Runnerを設定して、[Standard cluster mode](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters)でジョブを実行します。

GitLab RunnerをGKEで使用するように設定するには、次の手順に従います:

1. [環境をセットアップ](#set-up-your-environment)。
1. [クラスターを作成して接続](#create-and-connect-to-a-cluster)。
1. [Kubernetes Operatorをインストールして設定](#install-and-configure-the-kubernetes-operator)。
1. オプション。任意。[設定が成功したことを確認](#verify-your-configuration)。

## はじめる前 {#before-you-begin}

GitLab RunnerをGKEで使用するように設定する前に、以下を行う必要があります:

- メンテナーロール以上のGitLabプロジェクトが必要です。GitLabプロジェクトがない場合は、[作成](../../user/project/_index.md)できます。
- [プロジェクトRunner認証トークンを取得](../../ci/runners/runners_scope.md#create-a-project-runner-with-a-runner-authentication-token)。
- GitLab Runnerをインストールします。

## 環境をセットアップ {#set-up-your-environment}

GKEでGitLab Runnerを設定および使用するためのツールをインストールします。

1. [Google Cloud CLIをインストールして設定](https://cloud.google.com/sdk/docs/install)。Google Cloud CLIを使用して、クラスターに接続します。
1. [kubectlをインストールして設定](https://kubernetes.io/docs/tasks/tools/)。kubectlを使用して、ローカル環境からリモートクラスターと通信します。

## クラスターを作成して接続 {#create-and-connect-to-a-cluster}

このステップでは、クラスターを作成して接続する方法について説明します。クラスターに接続すると、kubectlを使用して操作できます。

1. Google Cloud Platformで、[標準](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster)クラスターを作成します。

1. kubectl認証プラグインをインストールします:

   ```shell
   gcloud components install gke-gcloud-auth-plugin
   ```

1. クラスターに接続します:

   ```shell
   gcloud container clusters get-credentials CLUSTER_NAME --zone=CLUSTER_LOCATION
   ```

1. クラスターの設定を表示します:

   ```shell
   kubectl config view
   ```

1. クラスターに接続されていることを確認します:

   ```shell
   kubectl config current-context
   ```

## Kubernetes Operatorをインストールして設定 {#install-and-configure-the-kubernetes-operator}

これでクラスターができたので、Kubernetes Operatorをインストールして設定する準備ができました。

1. `cert-manager`をインストールします。証明書マネージャーが既にインストールされている場合は、このステップをスキップしてください:

   ```shell
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml
   ```

1. Operator Lifecycle Manager（OLM）をインストールします。OLMは、クラスター上で実行されるKubernetes Operatorを管理するツールです:

   ```shell
   curl --silent --location "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.24.0/install.sh" \
    | bash -s v0.24.0
   ```

1. Kubernetes Operatorをインストールします:

   ```shell
   kubectl create -f https://operatorhub.io/install/gitlab-runner-operator.yaml
   ```

1. Operator Lifecycle Manager v0.25.0以降のみ。独自の証明書マネージャーを追加するか、`cert-manager`を使用します。

   - 独自の証明書プロバイダーを追加するには、次の手順に従います:

     1. `gitlab-runner-operator.yaml`で、`env`設定で証明書ネームスペースと証明書名を定義します:

        ```shell
        cat > gitlab-runner-operator.yaml << EOF
        apiVersion: operators.coreos.com/v1alpha1
        kind: Subscription
        metadata:
        name: gitlab-runner-operator
        namespace: gitlab-ns
        spec:
        channel: stable
        name: gitlab-runner-operator
        source: operatorhubio-catalog
        ca: webhook-server-cert
        sourceNamespace: olm
        config:
        env:
           - name: CERTIFICATE_NAMESPACE
           value: cert_namespace_desired_value
           - name: CERTIFICATE_NAME
           value: cert_name_desired_value
        EOF
        ```

     1. `gitlab-runner-operator.yaml`をKubernetesクラスターに適用します:

        ```shell
        kubectl apply -f gitlab-runner-operator.yaml
        ```

   - `cert-manager`を使用するには、次の手順に従います:

     1. `certificate-issuer-install.yaml`を使用して、Operatorのインストールに加えて、デフォルトネームスペースに`Certificate`と`Issuer`をインストールします:

        ```shell
        cat > certificate-issuer-install.yaml << EOF
        apiVersion: v1
        kind: Namespace
        metadata:
        labels:
           app.kubernetes.io/component: controller-manager
           app.kubernetes.io/managed-by: olm
           app.kubernetes.io/name: gitlab-runner-operator
        name: gitlab-runner-system
        ---
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
        name: gitlab-runner-serving-cert
        namespace: gitlab-runner-system
        spec:
        dnsNames:
        - gitlab-runner-webhook-service.gitlab-runner-system.svc
        - gitlab-runner-webhook-service.gitlab-runner-system.svc.cluster.local
        issuerRef:
          kind: Issuer
          name: gitlab-runner-selfsigned-issuer
        secretName: webhook-server-cert
        ---
        apiVersion: cert-manager.io/v1
        kind: Issuer
        metadata:
        name: gitlab-runner-selfsigned-issuer
        namespace: gitlab-runner-system
        spec:
        selfSigned: {}
        EOF
        ```

     1. `certificate-issuer-install.yaml`をKubernetesクラスターに適用します:

        ```shell
        kubectl create -f certificate-issuer-install.yaml
        ```

1. GitLabプロジェクトから`runner-registration-token`を含むシークレットを作成します:

   ```shell
    cat > gitlab-runner-secret.yml << EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: gitlab-runner-secret
    type: Opaque
    stringData:
      runner-token: YOUR_RUNNER_AUTHENTICATION_TOKEN
    EOF
   ```

1. シークレットを適用します:

   ```shell
   kubectl apply -f gitlab-runner-secret.yml
   ```

1. カスタムリソース定義ファイルを作成し、次の情報を含めます:

   ```shell
    cat > gitlab-runner.yml << EOF
    apiVersion: apps.gitlab.com/v1beta2
    kind: Runner
    metadata:
      name: gitlab-runner
    spec:
      gitlabUrl: https://gitlab.example.com
      buildImage: alpine
      token: gitlab-runner-secret
    EOF
   ```

1. カスタムリソース定義ファイルを適用します:

   ```shell
   kubectl apply -f gitlab-runner.yml
   ```

以上です。GitLab RunnerをGKEで使用するように設定しました。次の手順では、設定が機能しているかどうかを確認できます。

## 設定を確認 {#verify-your-configuration}

RunnerがGKEクラスターで実行されているかどうかを確認するには、次のいずれかの方法があります:

- 次のコマンドを使用します:

  ```shell
  kubectl get pods
  ```

  次の出力が表示されます。これは、RunnerがGKEクラスターで実行されていることを示しています:

  ```plaintext
  NAME                             READY   STATUS    RESTARTS   AGE
  gitlab-runner-hash-short_hash    1/1     Running   0          5m
  ```

- GitLabでジョブログを確認します:
  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. 左側のサイドバーで、**ビルド** > **ジョブ**を選択して、ジョブを見つけます。
  1. ジョブログを表示するには、ジョブステータスを選択します。
