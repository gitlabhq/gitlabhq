---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: GitLabのGit LFSのレート制限を設定します。
title: Git LFSのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Git LFS (Large File Storage)](../../topics/git/lfs/_index.md)は、大きなファイルを処理するためのGit拡張機能です。リポジトリでGit LFSを使用している場合、一般的なGit操作で多数のGit LFSリクエストが生成されることがあります。[一般的なユーザーとIPのレート制限](user_and_ip_rate_limits.md)を適用できますが、一般的な設定をオーバーライドして、Git LFSリクエストに追加の制限を適用することもできます。このオーバーライドにより、Webアプリケーションのセキュリティと耐久性を向上させることができます。

## GitLab.com {#on-gitlabcom}

GitLab.comでは、Git LFSリクエストは[認証されたWebリクエストのレート制限](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)の対象となります。これらの制限は、ユーザーあたり1分あたり1000リクエストに設定されています。

アップロードまたはダウンロードされた各Git LFSオブジェクトは、この制限にカウントされるHTTPリクエストを生成します。

{{< alert type="note" >}}

複数の大きなファイルを含むプロジェクトでは、HTTPレート制限エラーが発生する可能性があります。このエラーは、CI/CDパイプラインのような自動化された環境で、単一のIPアドレスから実行された場合に、クローンまたはプル中に発生します。

{{< /alert >}}

## GitLab Self-Managed {#on-gitlab-self-managed}

Git LFSのレート制限は、GitLabセルフマネージドインスタンスではデフォルトで無効になっています。管理者は、Git LFSトラフィック専用のレート制限を特に設定できます。有効にすると、これらの専用LFSのレート制限は、デフォルトの[ユーザーとIPのレート制限](user_and_ip_rate_limits.md)をオーバーライドします。

### Git LFSのレート制限を設定する {#configure-git-lfs-rate-limits}

前提要件: 

- インスタンスの管理者である。

Git LFSのレート制限を設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Git LFSのレート制限**を展開します。
1. **認証されたGit LFSリクエストレート制限を有効にする**を選択します。
1. **ユーザーあたりの期間あたりの認証された最大Git LFSリクエスト**の値を入力します。
1. **認証された Git LFS レート制限期間 (秒単位)**の値を入力します。
1. **変更を保存**を選択します。

## 関連トピック {#related-topics}

- [レート制限](../../security/rate_limits.md)
- [ユーザーとIPのレート制限](user_and_ip_rate_limits.md)
