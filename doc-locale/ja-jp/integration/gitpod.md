---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabプロジェクト用に、事前構築済みの開発環境を構築および設定するには、Onaを使用します。
title: Ona
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

[Ona](https://ona.com/)（旧Gitpod）を使用すると、開発環境をコードとして記述して、GitLabプロジェクト用に完全にセットアップ、コンパイル、テストされた開発環境を構築できます。開発環境は自動化されているだけでなく、事前構築済みであるため、OnaはCI/CDサーバーのようにGitブランチを継続的にビルドします。

つまり、依存関係がダウンロードされるのを待つ必要がなく、すぐにコードのビルドを開始できます。Onaを使用すると、ブラウザーから任意のプロジェクト、ブランチ、マージリクエストでコードをすぐに開始できます。

GitLab Onaインテグレーションを使用するには、GitLabインスタンスとその設定で有効にする必要があります。対象ユーザー:

- GitLab.comのユーザーは、[ユーザー設定で有効](#enable-ona-in-your-user-preferences)にした後、すぐに使用できます。
- GitLab Self-Managedインスタンスのユーザーは、次の後に使用できます:
  1. [GitLabの管理者によって有効化および設定されている](#configure-a-gitlab-self-managed-instance)。
  1. [ユーザー設定で有効](#enable-ona-in-your-user-preferences)になっている。

Onaの詳細については、Onaの[機能](https://ona.com/)と[ドキュメント](https://ona.com/docs)を参照してください。

## ユーザー設定でOnaを有効にする {#enable-ona-in-your-user-preferences}

GitLabインスタンスでOnaインテグレーションが有効になっている場合、自身で有効にするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **設定**を選択します。
1. **設定**で、**インテグレーション**セクションを見つけます。
1. **Enable Ona integration**（Onaインテグレーションを有効にする）チェックボックスを選択し、**変更を保存**を選択します。

## GitLab Self-Managedインスタンスを設定する {#configure-a-gitlab-self-managed-instance}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedインスタンスの場合、GitLabの管理者は、以下を実行する必要があります:

1. GitLabでOnaインテグレーションを有効にする:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**設定** > **一般**を選択します。
   1. **Ona**設定セクションを展開。
   1. **Enable Ona integration**（Onaインテグレーションを有効にする）チェックボックスを選択します。
   1. OnaインスタンスのURL（例: `https://app.ona.com`）を入力します。
   1. **変更を保存**を選択します。
1. Onaにインスタンスを登録します。詳細については、[Onaのドキュメント](https://ona.com/docs/ona/source-control/gitlab)を参照してください。

GitLabユーザーは、[Onaインテグレーションを自分で有効に](#enable-ona-in-your-user-preferences)できます。

## GitLabでOnaを起動する {#launch-ona-in-gitlab}

[Onaを有効に](#enable-ona-in-your-user-preferences)すると、次のいずれかの方法でGitLabから起動できます:

- プロジェクトリポジトリから:
  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. 右上にある**コード** > **Ona**を選択します。

- マージリクエストから: 
  1. マージリクエストに移動します。
  1. 右上隅で、**コード** > **Open in Ona**（Onaで開く）を選択します。

Onaはブランチの開発環境をビルドます。
