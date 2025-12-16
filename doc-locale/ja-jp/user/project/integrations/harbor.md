---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Harbor
description: プラットフォーム全体のアーティファクトを管理するために、GitLabプロジェクトのオープンソースコンテナレジストリとしてHarborを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabプロジェクトのコンテナレジストリとしてHarborを使用できます。

[Harbor](https://goharbor.io/)は、KubernetesやDockerのようなクラウドネイティブコンピューティングプラットフォーム全体のアーティファクトを管理するのに役立つオープンソースレジストリです。

Harborインテグレーションは、GitLab CI/CDとコンテナイメージリポジトリが必要な場合に役立ちます。

## 前提要件 {#prerequisites}

Harborインスタンスで、以下を確認してください:

- 統合されるプロジェクトが作成済みであること。
- 認証済みユーザーが、Harborプロジェクトでイメージをプル、プッシュ、および編集する権限を持っていること。

## GitLabを設定する {#configure-gitlab}

GitLabは、グループまたはプロジェクトレベルでのHarborプロジェクトの統合をサポートしています。GitLabで次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Harbor**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. Harborの設定情報を入力します:
   - **Harbor URL**: このGitLabプロジェクトにリンクされているHarborインスタンスのベースURL。たとえば`https://harbor.example.net`などです。
   - **Harborのプロジェクト名**: Harborインスタンス内のプロジェクト名。たとえば`testproject`などです。
   - **ユーザー名**: Harborインスタンスでのユーザー名。[前提条件](#prerequisites)の要件を満たしている必要があります。
   - **パスワード**: あなたのユーザー名のパスワード。

1. **変更を保存**を選択します。

Harborインテグレーションが有効化された後:

- `$HARBOR_USERNAME`、`$HARBOR_HOST`、`$HARBOR_OCI`、`$HARBOR_PASSWORD`、`$HARBOR_URL`、および`$HARBOR_PROJECT`のグローバル変数がCI/CD用として作成されます。
- プロジェクトレベルの統合設定は、グループレベルの統合設定をオーバーライドします。

## セキュリティに関する考慮事項 {#security-considerations}

### Harbor APIへのリクエストを保護する {#secure-your-requests-to-the-harbor-apis}

Harborインテグレーションを介した各APIリクエストでは、Harbor APIへの接続に使用する認証情報は、`username:password`の組み合わせを使用します。安全に使用するための提案を以下に示します:

- 接続先のHarbor APIでTLSを使用します。
- お使いの認証情報で、（Harborへのアクセスについて）最小権限の原則に従ってください。
- お使いの認証情報にローテーションポリシーを設定してください。

### CI/CD変数のセキュリティ {#cicd-variable-security}

`.gitlab-ci.yml`ファイルにプッシュされた悪意のあるコードは、`$HARBOR_PASSWORD`を含む変数を侵害し、サードパーティサーバーに送信する可能性があります。詳細については、[CI/CD変数のセキュリティ](../../../ci/variables/_index.md#cicd-variable-security)を参照してください。

## Harbor変数を使用する {#use-harbor-variables}

### OCIレジストリでHelmチャートをプッシュする {#push-a-helm-chart-with-an-oci-registry}

HelmはデフォルトでOCIレジストリをサポートしています。OCIは[Harbor 2.0](https://github.com/goharbor/harbor/releases/tag/v2.0.0)以降でサポートされています。Helmの[ブログ](https://helm.sh/blog/storing-charts-in-oci/)と[ドキュメント](https://helm.sh/docs/topics/registries/#enabling-oci-support)でOCIの詳細をお読みください。

```yaml
helm:
  stage: helm
  image:
    name: dtzar/helm-kubectl:latest
    entrypoint: ['']
  variables:
    # Enable OCI support (not required since Helm v3.8.0)
    HELM_EXPERIMENTAL_OCI: 1
  script:
    # Log in to the Helm registry
    - helm registry login "${HARBOR_URL}" -u "${HARBOR_USERNAME}" -p "${HARBOR_PASSWORD}"
    # Package your Helm chart, which is in the `test` directory
    - helm package test
    # Your helm chart is created with <chart name>-<chart release>.tgz
    # You can push all building charts to your Harbor repository
    - helm push test-*.tgz ${HARBOR_OCI}/${HARBOR_PROJECT}
```
