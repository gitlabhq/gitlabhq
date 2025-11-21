---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsを使用してAmazon ECSにデプロイする
---

Kubernetesを使用する代わりに、デプロイプラットフォームとしてAmazon Web Services ECSをターゲットにすることを選択できます。

Auto DevOpsからAmazon Web Services ECSを起動するには、特定のCI/CD変数を追加する必要があります。これを行うには、次の手順に従ってください。:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **Auto DevOps**を展開します。
1. Auto DevOpsデプロイ中にターゲットとするAWSプラットフォームを、次のいずれかの値を持つ`AUTO_DEVOPS_PLATFORM_TARGET`変数(へんすう)を追加して指定します。:
   - ターゲットとするサービスが起動タイプFARGATEである必要がある場合は、`FARGATE`。
   - ECSにデプロイする際に起動タイプのチェックを適用しない場合は`ECS`。

パイプラインをトリガーすると、Auto DevOpsが有効になっており、[変数としてAWSの認証情報を正しく入力](../../../ci/cloud_deployment/_index.md#authenticate-gitlab-with-aws)していれば、アプリケーションはAmazon Web Services ECSにデプロイされます。

有効な`AUTO_DEVOPS_PLATFORM_TARGET`変数と、プロジェクトに紐づいたKubernetesクラスタリングの両方がある場合、Kubernetesへのデプロイのみが実行されます。

{{< alert type="warning" >}}

`AUTO_DEVOPS_PLATFORM_TARGET`変数を`ECS`に設定すると、[`Jobs/Deploy/ECS.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml)で定義されたジョブがトリガーされます。ただし、それ自体に[含める](../../../ci/yaml/_index.md#includetemplate)ことは推奨されません。このテンプレートは、Auto DevOpsでのみ使用するように設計されています。単独で含めると、予期せず変更され、パイプラインが失敗する可能性があります。また、このテンプレート内のジョブ名も変更される可能性があります。名前が変更されたときにオーバーライドが機能しなくなるため、独自のパイプラインでこれらのジョブ名をオーバーライドしないでください。

{{< /alert >}}
