---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 運用ダッシュボード
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

運用ダッシュボードには、各プロジェクトの運用状態の概要（パイプラインとアラートのステータスなど）が表示されます。

ダッシュボードにアクセスするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択します。
1. **あなたの作業**を選択します。
1. **オペレーション**を選択します。

## ダッシュボードにプロジェクトを追加する {#adding-a-project-to-the-dashboard}

ダッシュボードにプロジェクトを追加するには、次の手順に従います:

1. アラートに、`gitlab_environment_name`ラベルが入力されていることを確認します（[Prometheusで設定したアラート](../../operations/incident_management/integrations.md#expected-prometheus-request-attributes)）。この値は、GitLabの環境名と一致する必要があります。`production`環境でのみアラートを表示できます。
1. ダッシュボードのホーム画面で**プロジェクトを追加**を選択します。
1. **プロジェクトを検索**フィールドを使用して、1つまたは複数のプロジェクトを検索して追加します。
1. **プロジェクトを追加**を選択します。

追加されると、ダッシュボードには、プロジェクトのアクティブなアラートの数、最後のコミット、パイプラインステータス、および最後にデプロイされた日時が表示されます。

オペレーションと[環境](../../ci/environments/environments_dashboard.md)のダッシュボードは、プロジェクトの同じリストを共有します。一方のプロジェクトを追加または削除すると、もう一方のプロジェクトが追加または削除されます。

![プロジェクトを含む運用ダッシュボード](img/index_operations_dashboard_with_projects_v11_10.png)

## ダッシュボードでのプロジェクトの配置 {#arranging-projects-on-a-dashboard}

プロジェクトカードをドラッグして、順序を変更できます。カードの順序は現在ブラウザにのみ保存されるため、他のユーザーのダッシュボードは変更されません。

## サインイン時にデフォルトのダッシュボードにする {#making-it-the-default-dashboard-when-you-sign-in}

運用ダッシュボードは、サインイン時に表示されるデフォルトのGitLabダッシュボードにすることもできます。デフォルトにするには、[プロフィールの設定](../profile/preferences.md)を参照してください。
