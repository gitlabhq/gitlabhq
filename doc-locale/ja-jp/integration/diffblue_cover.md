---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Diffblue Cover GitLabインテグレーションを設定する方法 - Coverパイプラインfor GitLab
title: Diffblue Cover
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDパイプラインに[Diffblue Cover](https://www.diffblue.com/)強化学習AIツールを統合して、GitLabプロジェクトのJava単体テストを自動的に作成および保守できます。Diffblue Coverパイプラインfor GitLabインテグレーションを使用すると、以下を自動的に実行できます:

- プロジェクトのベースライン単体テストスイートを作成します。
- 新しいコードの新しい単体テストを作成します。
- コード内の既存の単体テストを更新します。
- 不要になったコード内の既存の単体テストを削除します。

![Coverパイプラインfor GitLab Basic MR Process](img/diffblue_cover_workflow_after_v16_8.png)

## インテグレーションを設定する {#configure-the-integration}

GitLabのパイプラインにDiffblue Coverを統合するには、次の手順に従います:

1. Diffblue Coverインテグレーションを見つけて設定します。
1. GitLabパイプラインエディタとDiffblue Coverパイプラインテンプレートを使用して、サンプルプロジェクトのパイプラインを設定します。
1. プロジェクトの完全なベースライン単体テストスイートを作成します。

### Diffblue Coverを設定する {#configure-diffblue-cover}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   - サンプルプロジェクトで統合をテストする場合は、Diffblue [Spring Petclinic](https://github.com/diffblue/demo-spring-petclinic)サンプルプロジェクトを[インポート](../user/project/import/repo_by_url.md)できます。
1. **設定** > **インテグレーション**を選択します。
1. **Diffblue Cover**（Diffblue Cover）を見つけて、**設定する**を選択します。
1. フィールドに入力します:

   - **有効**チェックボックスを選択します。
   - ウェルカムメールまたは組織から提供されたDiffblue Coverの**ライセンスキー**を入力します。必要に応じて、[**Diffblue Coverを試す**](https://www.diffblue.com/try-cover/gitlab/)リンクを選択して、トライアルにサインアップしてください。
   - Diffblue Coverがプロジェクトにアクセスできるように、GitLabアクセストークン（**名前**と**シークレット**）の詳細を入力します。通常は、`Developer`ロールのGitLab [プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md)と、`api`および`write_repository`スコープを使用します。必要に応じて、`Developer`ロールの[グループアクセストークン](../user/group/settings/group_access_tokens.md)または[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)と、`api`および`write_repository`スコープを再度使用できます。

     {{< alert type="note" >}}

     過剰な権限を持つアクセストークンを使用すると、セキュリティ上のリスクがあります。PATを使用する場合は、プロジェクトのみにアクセスが制限された専用ユーザーを作成して、トークンがリークした場合の影響を最小限に抑えるすることを検討してください。

     {{< /alert >}}

1. **変更を保存**を選択します。Diffblue Coverインテグレーションが<mark style="color:green;">**有効**</mark>になり、プロジェクトで使用できるようになりました。

### パイプラインを設定する {#configure-a-pipeline}

ここでは、Diffblue Coverの最新バージョンをダウンロードし、プロジェクトをビルドし、プロジェクトのJava単体テストを作成し、変更をブランチにコミットする、プロジェクトのマージリクエストパイプラインを作成します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. [`Diffblue-Cover.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Diffblue-Cover.gitlab-ci.yml)の内容をプロジェクトの`.gitlab-ci.yml`ファイルにコピーします。

   {{< alert type="note" >}}

   Diffblue Coverパイプラインテンプレートを独自のプロジェクトおよび既存のパイプラインファイルで使用する場合は、Diffblueテンプレートのコンテンツをファイルに追加し、必要に応じて変更します。詳細については、Diffblueドキュメントの[Coverパイプラインfor GitLab](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab)を参照してください。

   {{< /alert >}}

1. コミットメッセージを入力します。
1. 新しい**ブランチ**名を入力します。たとえば`add-diffblue-cover-pipeline`などです。
1. **Start a new merge request with these changes**（これらの変更で新しいマージリクエストを開始）を選択します。
1. **変更をコミットする**を選択します。

### ベースライン単体テストスイートを作成する {#create-a-baseline-unit-test-suite}

1. **新しいマージリクエスト**フォームで、**タイトル**（例: 「Coverパイプラインを追加してベースラインの単体テストスイートを作成」）を入力し、他のフィールドに入力します。
1. **マージリクエストを作成**を選択します。マージリクエストパイプラインはDiffblue Coverを実行して、プロジェクトのベースライン単体テストスイートを作成します。
1. パイプラインが完了すると、**変更**タブから変更をレビューできます。問題がなければ、更新をリポジトリにマージします。プロジェクトリポジトリの`src/test`フォルダーに移動して、Diffblue Coverによって作成された単体テスト（`*DiffblueTest.java`というサフィックスが付いています）を確認します。

## 後続のコード変更 {#subsequent-code-changes}

プロジェクトに対して後続のコード変更を実行すると、マージリクエストパイプラインはDiffblue Coverを実行しますが、関連付けられたテストのみを更新します。結果として得られる差分を分析して、新しい動作をチェックし、リグレッションをキャッチし、コードに対する計画外の動作変更を見つけることができます。

![緑色でテストが追加され、赤色で削除されたコード変更を示すマージリクエストの差分。](img/diffblue_cover_diff_v16_8.png)

## 次の手順 {#next-steps}

このトピックでは、Coverパイプラインfor GitLabの主要な機能の一部と、パイプラインでインテグレーションを使用する方法について説明します。パイプラインテンプレートで`dcover`コマンドを介して提供される、より広くより深い機能は、単体テスト機能をさらに展開するために実装できます。詳細については、Diffblueドキュメントの[Coverパイプラインfor GitLab](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab)を参照してください。
