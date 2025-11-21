---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabをGitGuardianとインテグレーションして、悪用される前にポリシー違反とセキュリティイシューのアラートを取得します。
title: GitGuardian
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で`git_guardian_integration`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435706)されました。デフォルトでは有効になっています。GitLab.comで無効になりました。
- GitLab 17.7で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391)になりました。機能フラグ`git_guardian_integration`は削除されました。

{{< /history >}}

[GitGuardian](https://www.gitguardian.com/)は、ソースコードリポジトリ内のAPIキーやパスワードなどの機密情報を検出するサイバーセキュリティサービスです。Gitリポジトリをスキャンし、ポリシー違反のアラートを送信し、ハッカーが悪用する前に組織がセキュリティイシューを修正するのを支援します。

GitGuardianポリシーに基づいてコミットを拒否するようにGitLabを設定できます。

GitGuardianインテグレーションをセットアップするには:

1. [GitGuardian APIトークンを作成](#create-a-gitguardian-api-token)。
1. [プロジェクトのGitGuardianインテグレーションを設定](#set-up-the-gitguardian-integration-for-your-project)。

## GitGuardian APIトークンを作成 {#create-a-gitguardian-api-token}

前提要件: 

- GitGuardianアカウントを持っている必要があります。

APIトークンを作成するには:

1. GitGuardianアカウントにサインインします。
1. サイドバーの**API**セクションに移動します。
1. APIセクションのサイドバーで、**パーソナルアクセストークン**ページに移動します。
1. **トークンを作成**を選択します。トークン作成ダイアログが開きます。
1. トークン情報を提供します:
   - 目的を識別するために、APIトークンにわかりやすい名前を付けます。たとえば`GitLab integration token`などです。
   - 適切な有効期限を選択します。
   - **scan scope**（スキャンスコープ）チェックボックスを選択します。これは、インテグレーションに必要な唯一のものです。
1. **トークンを作成**を選択します。
1. トークンを生成したら、クリップボードにコピーします。このトークンは機密情報であるため、安全に保管してください。

これで、インテグレーションに使用できるGitGuardian APIトークンが正常に作成されました。

## プロジェクトのGitGuardianインテグレーションを設定 {#set-up-the-gitguardian-integration-for-your-project}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

APIトークンを作成してコピーしたら、GitLabがコミットを拒否するように設定します:

プロジェクトのインテグレーションを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **GitGuardian**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスを選択します。
1. **APIトークン**で、[GitGuardianからトークン値をペーストしてください](#create-a-gitguardian-api-token)。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

GitLabは、GitGuardianポリシーに基づいてコミットを拒否する準備ができました。

## シークレット検出をスキップ {#skip-secret-detection}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152064)されました。

{{< /history >}}

必要に応じて、GitGuardianシークレット検出をスキップできます。プッシュ内のすべてのコミットに対してシークレット検出をスキップするオプションは、[ネイティブシークレット検出](../../application_security/secret_detection/secret_push_protection/_index.md#skip-secret-push-protection)のオプションと同じです。次のいずれかの操作を行います:

- コミットメッセージの1つに`[skip secret push protection]`を追加します。
- `secret_push_protection.skip_all` [プッシュオプション](../../../topics/git/commit.md#push-options-for-gitguardian-integration)を使用します。

## 既知の問題 {#known-issues}

- プッシュが遅延したり、タイムアウトしたりする可能性があります。GitGuardianインテグレーションを使用する場合:
  - プッシュはサードパーティに送信されます。
  - GitLabは、GitGuardianまたはGitGuardianプロセスの接続を制御できません。
- [GitGuardian APIの制限](https://api.gitguardian.com/docs#operation/multiple_scan)により、インテグレーションは1 MBを超えるサイズのファイルを無視します。それらはスキャンされません。
- プッシュされたファイルのファイル名が256文字を超える場合、プッシュは失敗します。
- 詳細については、[GitGuardian APIドキュメント](https://api.gitguardian.com/docs#operation/multiple_scan)を参照してください。

以下のトラブルシューティング手順は、これらの問題の一部を軽減する方法を示しています。

## トラブルシューティング {#troubleshooting}

GitGuardianインテグレーションを使用すると、次の問題が発生する可能性があります。

### `500` HTTPエラー {#500-http-errors}

HTTP `500`エラーが発生する可能性があります。

この問題は、変更されたファイルが多いコミットのリクエストがタイムアウトした場合に発生します。

この問題が、1つのコミットで50個を超えるファイルを変更した場合に発生した場合:

1. 変更をより小さなコミットに分割します。
1. より小さなコミットを1つずつプッシュします。

### エラー: `Filename: ensure this value has at most 256 characters` {#error-filename-ensure-this-value-has-at-most-256-characters}

HTTP `400`エラーが発生し、`Filename: ensure this value has at most 256 characters`と表示されることがあります。

この問題は、そのコミットでプッシュしている変更されたファイルの一部に、(パスではなく) 256文字より長いファイル名がある場合に発生します。

回避策は、可能であればファイル名を短くすることです。たとえば、フレームワークによって自動的に生成されたためにファイル名を短縮できない場合は、インテグレーションを無効にして、再度プッシュしてみてください。必要に応じて、後でインテグレーションを再度有効にすることを忘れないでください。
