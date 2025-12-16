---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetesへのデプロイを開始する
---

このページでは、GitLabでサポートされている方法を使用したKubernetesへのデプロイについて説明します。最終的には、以下を理解できるようになります:

- Fluxを使用してデプロイする方法
- GitLab CI/CDパイプラインから、クラスターに対してデプロイまたはコマンドを実行する方法
- 最良の結果を得るために、FluxとGitLab CI/CDを組み合わせる方法

## はじめる前 {#before-you-begin}

このチュートリアルは、[KubernetesクラスターをGitLabに接続する](getting_started.md)で作成したプロジェクトを基にしています。そのチュートリアルで作成したのと同じプロジェクトを使用します。ただし、接続されたKubernetesクラスターとブートストラップされたFluxインストールを含む任意のプロジェクトを使用できます。

## GitLab CI/CDからクラスターに対してコマンドを実行する {#run-commands-against-your-cluster-from-gitlab-cicd}

Kubernetes用エージェントは、[GitLab CI/CDパイプラインとインテグレーションします](ci_cd_workflow.md)。CI/CDを使用して、安全かつスケーラブルな方法で、`kubectl apply`や`helm upgrade`などのコマンドをクラスターに対して実行できます。

このセクションでは、GitLabパイプラインインテグレーションを使用して、クラスターにシークレットを作成し、それを使用してGitLabコンテナレジストリにアクセスします。このチュートリアルの残りの部分では、デプロイされたシークレットを使用します。

1. `read_registry`スコープを持つ[デプロイトークンを作成](../../project/deploy_tokens/_index.md#create-a-deploy-token)します。
1. デプロイトークンとユーザー名を、`CONTAINER_REGISTRY_ACCESS_TOKEN`と`CONTAINER_REGISTRY_ACCESS_USERNAME`というCI/CD変数として保存します。
   - 両方の変数について、環境を`container-registry-secret*`に設定します。
   - `CONTAINER_REGISTRY_ACCESS_TOKEN`の場合:
      - [変数をマスクします](../../../ci/variables/_index.md#mask-a-cicd-variable)。
      - [変数を保護します](../../../ci/variables/_index.md#protect-a-cicd-variable)。
1. 次のスニペットを`.gitlab-ci.yml`ファイルに追加し、プロジェクトのパスに一致するように両方の`AGENT_KUBECONTEXT`変数を更新します:

   ```yaml
   stages:
   - setup
   - deploy
   - stop

   create-registry-secret:
     stage: setup
     image: "portainer/kubectl-shell:latest"
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # We need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret gitlab-registry-auth -n flux-system --ignore-not-found
       - kubectl create secret docker-registry gitlab-registry-auth -n flux-system
         --docker-password="${CONTAINER_REGISTRY_ACCESS_TOKEN}" --docker-username="${CONTAINER_REGISTRY_ACCESS_USERNAME}" --docker-server="${CI_REGISTRY}"
     environment:
       name: container-registry-secret
       on_stop: delete-registry-secret

   delete-registry-secret:
     stage: stop
     image: ""
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # We need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret -n flux-system gitlab-registry-auth
     environment:
       name: container-registry-secret
       action: stop
     when: manual
   ```

続行する前に、CI/CDで他のコマンドをどのように実行するかを検討してください。

## 単純なマニフェストをOCIイメージにビルドし、クラスターにデプロイする {#build-a-simple-manifest-into-an-oci-image-and-deploy-it-to-the-cluster}

本番環境のユースケースでは、GitリポジトリとFluxCDの間のキャッシュレイヤーとしてOCIリポジトリを使用するのがベストプラクティスです。FluxCDはOCIリポジトリ内の新しいイメージをチェックし、GitLabパイプラインはFlux準拠のOCIイメージをビルドします。エンタープライズのベストプラクティスについて詳しくは、[エンタープライズに関する考慮事項](enterprise_considerations.md)をご覧ください。

このセクションでは、単純なKubernetesマニフェストをOCIアーティファクトとしてビルドし、それをクラスターにデプロイします。

1. 次の`flux` CLIコマンドを実行して、指定されたOCIイメージを取得してコンテンツをデプロイする場所をFluxに指示します。GitLabインスタンスの`--url`の値を調整します。コンテナレジストリのURLは、**デプロイ** > **コンテナレジストリ**にあります。作成された`clusters/testing/nginx.yaml`ファイルを調べて、Fluxがデプロイするマニフェストをどのように見つけるかをよりよく理解できます。

   ```shell
   flux create source oci nginx-example \
    --url oci://registry.gitlab.example.org/my-group/optional-subgroup/my-repository/nginx-example \
    --tag latest \
    --secret-ref gitlab-registry-auth \
    --interval 1m \
    --namespace flux-system \
    --export > clusters/testing/nginx.yaml
    flux create kustomization nginx-example \
    --source OCIRepository/nginx-example \
    --path "." \
    --prune true \
    --target-namespace default \
    --interval 1m \
    --namespace flux-system \
    --export >> clusters/testing/nginx.yaml
   ```

1. 例として、NGINXをデプロイします。次のYAMLを`clusters/applications/nginx/nginx.yaml`に追加します:

   ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-example
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: nginx-example
      template:
        metadata:
          labels:
            app: nginx-example
        spec:
          containers:
            - name: nginx
              image: nginx:1.25
              ports:
                - containerPort: 80
                  protocol: TCP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-example
      namespace: default
    spec:
      ports:
        - port: 80
          targetPort: 80
          protocol: TCP
      selector:
        app: nginx-example
   ```

1. 次に、前のYAMLをパッケージ化してOCIイメージにします。次のスニペットで`.gitlab-ci.yml`ファイルを拡張し、`AGENT_KUBECONTEXT`変数を再度更新します:

   ```yaml
    nginx-deployment:
        stage: deploy
        variables:
            IMAGE_NAME: nginx-example   # Image name to push
            IMAGE_TAG: latest
            MANIFEST_PATH: "./clusters/applications/nginx"
            IMAGE_TITLE: NGINX example   # Image title to use in OCI annotation
            AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
            FLUX_OCI_REPO_NAME: nginx-example  # Flux OCIRepository to reconcile
            NAMESPACE: flux-system  # Namespace for the OCIRepository resource
        # This section configures a GitLab environment for the nginx deployment specifically
        environment:
            name: applications/nginx
            kubernetes:
                agent: $AGENT_KUBECONTEXT
                dashboard:
                  namespace: default
                  flux_resource_path: kustomize.toolkit.fluxcd.io/v1/namespaces/flux-system/kustomizations/nginx-example  # We will deploy this resource in the next step
        image:
            name: "fluxcd/flux-cli:v2.4.0"
            entrypoint: [""]
        before_script:
            - kubectl config use-context $AGENT_KUBECONTEXT
        script:
            # This line builds and pushes the OCI container to the GitLab container registry.
            # You can read more about this command in https://fluxcd.io/flux/cmd/flux_push_artifact/
            - flux push artifact oci://${CI_REGISTRY_IMAGE}/${IMAGE_NAME}:${IMAGE_TAG}
                --source="${CI_REPOSITORY_URL}"
                --path="${MANIFEST_PATH}"
                --revision="${CI_COMMIT_SHORT_SHA}"
                --creds="${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}"
                --annotations="org.opencontainers.image.url=${CI_PROJECT_URL}"
                --annotations="org.opencontainers.image.title=${IMAGE_TITLE}"
                --annotations="com.gitlab.job.id=${CI_JOB_ID}"
                --annotations="com.gitlab.job.url=${CI_JOB_URL}"
            # This line triggers an immediate reconciliation of the resource. Otherwise Flux would reconcile following its configured reconciliation period.
            # You can read more about the various reconcile commands in https://fluxcd.io/flux/cmd/flux_reconcile/
            - flux reconcile source oci -n ${NAMESPACE} ${FLUX_OCI_REPO_NAME}
   ```

1. 変更をコミットしてプロジェクトにプッシュし、ビルドパイプラインが完了するのを待ちます。
1. 左側のサイドバーで、**操作** > **環境**を選択し、利用可能な[Kubernetesのダッシュボード](../../../ci/environments/kubernetes_dashboard.md)を確認します。`applications/nginx`環境は正常である必要があります。

## GitLabパイプラインアクセスの保護 {#secure-the-gitlab-pipeline-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

以前にデプロイされたエージェントは、`.gitlab/agents/testing/config.yaml`ファイルを使用して設定されます。デフォルトでは、この設定により、GitLabパイプラインが実行されるプロジェクトで設定されたクラスターへのアクセスが有効になります。デフォルトでは、このアクセスはデプロイされたエージェントのサービスアカウントを使用して、クラスターに対してコマンドを実行します。このアクセスは、静的なサービスアカウントIDに制限するか、CI/CDジョブをクラスター内のIDとして使用することで制限できます。最後に、通常のKubernetes RBACを使用して、クラスター内のCI/CDジョブのアクセスを制限できます。

このセクションでは、すべてのCI/CDジョブにIDを追加し、クラスター内でジョブを代理することで、CI/CDアクセスを制限します。

1. CI/CDジョブの代理を設定するには、`.gitlab/agents/testing/config.yaml`ファイルを編集し、次のスニペットを追加します（`path/to/project`を置き換えます）:

   ```yaml
   ci_access:
      projects:
         - id: my-group/optional-subgroup/my-repository
           access_as:
              ci_job: {}
   ```

1. CI/CDジョブにはまだクラスターバインディングがないため、GitLab CI/CDからKubernetesコマンドを実行することはできません。CI/CDジョブが`flux-system`ネームスペースに`Secret`オブジェクトを作成できるようにしましょう。次のコンテンツで`clusters/testing/gitlab-ci-job-secret-write.yaml`ファイルを作成します:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
      name: secret-manager
      namespace: default
   rules:
      - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["create", "delete"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
      name: gitlab-ci-secrets-binding
      namespace: default
   subjects:
      - kind: Group
        name: gitlab:ci_job
        apiGroup: rbac.authorization.k8s.io
   roleRef:
      kind: Role
      name: secret-manager
      apiGroup: rbac.authorization.k8s.io
   ```

1. CI/CDジョブがFluxCD調整もトリガーできるようにしましょう。次のコンテンツで`clusters/testing/gitlab-ci-job-flux-reconciler.yaml`ファイルを作成します:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-admin
   roleRef:
       name: flux-edit-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-view
   roleRef:
       name: flux-view-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ```

CI/CDアクセスについて詳しくは、[KubernetesクラスターでのGitLab CI/CDの使用](ci_cd_workflow.md)をご覧ください。

## リソースのクリーンアップ {#clean-up-resources}

完了するには、デプロイされたリソースを削除し、コンテナレジストリへのアクセスに使用したシークレットを削除しましょう:

1. `clusters/testing/nginx.yaml`ファイルを削除します。Fluxが、クラスターから関連リソースを削除します。
1. `container-registry-secret`環境を停止します。環境を停止すると、その`on_stop`ジョブがトリガーされ、クラスターからシークレットが削除されます。

## 次の手順 {#next-steps}

このチュートリアルの手法を使用して、プロジェクト全体のデプロイをスケールできます。OCIイメージは別のプロジェクトでビルドでき、Fluxが適切なレジストリを指している限り、Fluxはそれを取得します。この演習は読者に任されています。

さらに練習するには、`/clusters/testing/flux-system/gotk-sync.yaml`の元のFlux `GitRepository`を`OCIRepository`に変更してみてください。

最後に、FluxとKubernetesとのGitLabインテグレーションについて詳しくは、次のリソースをご覧ください:

- Kubernetesインテグレーションに関する[エンタープライズに関する考慮事項](enterprise_considerations.md)
- [運用コンテナスキャン](vulnerabilities.md)にエージェントを使用する
- [リモートワークスペース](../../workspace/_index.md)をエンジニアに提供するために、エージェントを使用します
