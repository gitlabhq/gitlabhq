---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitHubからGitLabへのプロジェクトのインポートのトラブルシューティング
description: "GitHubのインポートに関するトラブルシューティング: プロセスの失敗、プレフィックスの欠落、大規模プロジェクトのエラーなど。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitHubからGitLabにプロジェクトをインポートする際に、以下の問題が発生する可能性があります。

## 以前に失敗したインポートプロセスを手動で続行する {#manually-continue-a-previously-failed-import-process}

GitHubのインポートプロセスがリポジトリのインポートに失敗する場合があります。これにより、GitLabはプロジェクトのインポートプロセスを中断し、リポジトリを手動でインポートする必要があります。管理者は、失敗したインポートプロセスのリポジトリを手動でインポートできます:

1. Railsコンソールを開きます。
1. コンソールで次の一連のコマンドを実行します:

   ```ruby
   project_id = <PROJECT_ID>
   github_access_token =  <GITHUB_ACCESS_TOKEN>
   github_repository_path = '<GROUP>/<REPOSITORY>'

   github_repository_url = "https://#{github_access_token}@github.com/#{github_repository_path}.git"

   # Find project by ID
   project = Project.find(project_id)
   # Set import URL and credentials
   project.import_url = github_repository_url
   project.import_type = 'github'
   project.import_source = github_repository_path
   project.save!
   # Create an import state if the project was created manually and not from a failed import
   project.create_import_state if project.import_state.blank?
   # Set state to start
   project.import_state.force_start

   # Optional: If your import had certain optional stages selected or a timeout strategy
   # set, you can reset them here. Below is an example.
   # The params follow the format documented in the API:
   # https://docs.gitlab.com/ee/api/import.html#import-repository-from-github
   Gitlab::GithubImport::Settings
   .new(project)
   .write(
     timeout_strategy: "optimistic",
     optional_stages: {
       single_endpoint_issue_events_import: true,
       single_endpoint_notes_import: true,
       attachments_import: true,
       collaborators_import: true
     }
   )

   # Trigger import from second step
   Gitlab::GithubImport::Stage::ImportRepositoryWorker.perform_async(project.id)
   ```

## プレフィックスの欠落が原因でインポートが失敗する {#import-fails-due-to-missing-prefix}

GitLab 16.5では、`Import failed due to a GitHub error: (HTTP 406)`というエラーが発生する場合があります。

この問題が発生するのは、GitLab 16.5で、パスプレフィックス`api/v3`がGitHubインポーターから削除されたためです。これは、インポーターが`Gitlab::LegacyGithubImport::Client`を使用しなくなったために発生しました。このクライアントは、GitHub Enterprise URLからのインポート時に、`api/v3`プレフィックスを自動的に追加していました。

このエラーを回避するには、GitHub Enterprise URLからインポートする際に、[`api/v3`プレフィックスを追加](https://gitlab.com/gitlab-org/gitlab/-/issues/438358#note_1978902725)してください。

## 大規模プロジェクトのインポート時のエラー {#errors-when-importing-large-projects}

大規模なプロジェクトをインポートすると、GitHubインポーターでエラーが発生する場合があります。

### コメントの欠落 {#missing-comments}

GitHub APIには、約30,000を超える注記または差分注記をインポートできない制限があります。この制限に達すると、GitHub APIは代わりに次のエラーを返します:

```plaintext
In order to keep the API fast for everyone, pagination is limited for this resource. Check the rel=last link relation in the Link response header to see how far back you can traverse.
```

多数のコメントを含むGitHubプロジェクトをインポートする場合は、**Use alternative comments import method**（代替コメントインポート方法を使用） [インポートする追加項目](github.md#select-additional-items-to-import)チェックボックスをオンにします。この設定により、インポートを実行するために必要なネットワークリクエストの数が増えるため、インポートプロセスに時間がかかります。

## GitLabインスタンスがGitHubに接続できない {#gitlab-instance-cannot-connect-to-github}

GitLab 15.10を実行し、プロキシの背後にあるGitLab Self-Managedインスタンスは、`github.com`または`api.github.com`のドメイン名サービスを解決できません。GitLabインスタンスはインポート中にGitHubへの接続に失敗し、`github.com`および`api.github.com`エントリを[許可リスト（ローカルリクエスト用）](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加する必要があります。
