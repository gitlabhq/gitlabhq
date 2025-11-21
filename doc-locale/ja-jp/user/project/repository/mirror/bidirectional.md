---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 双方向ミラーを作成して、2つのGitリポジトリ間で変更をプッシュおよびプルします。
title: 双方向ミラーリング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

{{< alert type="warning" >}}

双方向ミラーリングは、競合を引き起こす可能性があります。

{{< /alert >}}

双方向[ミラーリング](_index.md)は、2つのリポジトリが互いにプルとプッシュの両方を行うように設定します。どちらのリポジトリもエラーなしに更新できるという保証はありません。

## 双方向ミラーリングにおける競合を軽減します {#reduce-conflicts-in-bidirectional-mirroring}

双方向ミラーリングを設定する場合は、競合に備えてリポジトリを準備してください。競合を軽減するように設定し、発生した場合の解決方法を設定します:

- [保護されたブランチのみをミラーリングする](_index.md#mirror-only-protected-branches)。いずれかのリモートでミラーリングされたコミットを書き換えると、競合が発生し、ミラーリングが失敗します。
- [両方のリモートでミラーするブランチを保護](../branches/protected.md)して、履歴の書き換えによって発生する競合を防ぎます。
- [プッシュイベント](../../integrations/webhook_events.md#push-events)を使用して、ミラーリングの遅延を軽減します。双方向ミラーリングは、同じブランチに対して互いに近い場所で作成されたコミットが競合を引き起こす競合状態を作成します。プッシュイベントは、競合状態を軽減するのに役立ちます。GitLabからのプッシュミラーリングは、保護ブランチをプッシュミラーリングする場合のみ、1分間に1回にレート制限されます。
- [事前受信フックの使用](#prevent-conflicts-by-using-a-pre-receive-hook)により、競合を防ぎます。

## を設定して、GitLabへの即時プルをトリガーします {#configure-a-webhook-to-trigger-an-immediate-pull-to-gitlab}

ダウンストリームインスタンスの[プッシュイベント](../../integrations/webhook_events.md#push-events)は、変更をより頻繁に同期することで、競合状態を軽減するのに役立ちます。

前提要件: 

- アップストリームのGitLabインスタンスで、[プッシュ](push.md#set-up-a-push-mirror-to-another-gitlab-instance-with-2fa-activated)と[プル](pull.md)ミラーを設定しました。

ダウンストリームインスタンスでを作成するには:

1. [API](../../../profile/personal_access_tokens.md) `API`スコープでパーソナルアクセストークンを作成します。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **Webhooks**を選択します。
1. **URL**を追加します。このユースケースでは、リポジトリの更新後に即時プルをトリガーする[プルミラーAPI](../../../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)リクエストを使用します:

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:id/mirror/pull?private_token=<your_access_token>
   ```

1. **Push Events**（プッシュイベント） を選択します。
1. **Add Webhook**（Webhookを追加）を選択します。

インテグレーションをテストするには、**テスト**を選択し、GitLabがエラーメッセージを返さないことを確認します。

## 事前受信フックを使用した競合の防止 {#prevent-conflicts-by-using-a-pre-receive-hook}

{{< alert type="warning" >}}

このソリューションは、Gitプッシュ操作のパフォーマンスに悪影響を及ぼします。これらはアップストリームのGitリポジトリにプロキシされるためです。

{{< /alert >}}

この設定では、1つのGitリポジトリが信頼できるアップストリームとして機能し、もう1つがダウンストリームとして機能します。このサーバー側の`pre-receive`フックは、最初にコミットをアップストリームリポジトリにプッシュした後にのみ、プッシュを受け入れます。このフックをダウンストリームリポジトリにインストールします。

例: 

```shell
#!/usr/bin/env bash

# --- Assume only one push mirror target
# Push mirroring remotes are named `remote_mirror_<id>`.
# This line finds the first remote and uses that.
TARGET_REPO=$(git remote | grep -m 1 remote_mirror)

proxy_push()
{
  # --- Arguments
  OLDREV=$(git rev-parse $1)
  NEWREV=$(git rev-parse $2)
  REFNAME="$3"

  # --- Pattern of branches to proxy pushes
  allowlist=$(expr "$branch" : "\(master\)")

  case "$refname" in
    refs/heads/*)
      branch=$(expr "$refname" : "refs/heads/\(.*\)")

      if [ "$allowlist" = "$branch" ]; then
        # handle https://git-scm.com/docs/git-receive-pack#_quarantine_environment
        unset GIT_QUARANTINE_PATH
        error="$(git push --quiet $TARGET_REPO $NEWREV:$REFNAME 2>&1)"
        fail=$?

        if [ "$fail" != "0" ]; then
          echo >&2 ""
          echo >&2 " Error: updates were rejected by upstream server"
          echo >&2 "   This is usually caused by another repository pushing changes"
          echo >&2 "   to the same ref. You may want to first integrate remote changes"
          echo >&2 ""
          return
        fi
      fi
      ;;
  esac
}

# Allow dual mode: run from the command line just like the update hook, or
# if no arguments are given, then run as a hook script:
if [ -n "$1" -a -n "$2" -a -n "$3" ]; then
  # Output to the terminal in command line mode. If someone wanted to
  # resend an email, they could redirect the output to sendmail themselves
  PAGER= proxy_push $2 $3 $1
else
  # Push is proxied upstream one ref at a time. It is possible for some refs
  # to succeed, and others to fail. This results in a failed push.
  while read oldrev newrev refname
  do
    proxy_push $oldrev $newrev $refname
  done
fi
```

このサンプルにはいくつかの制限があります:

- 変更なしでは、ユースケースでは機能しない場合があります:
  - ミラーのさまざまな種類の認証メカニズムを考慮していません。
  - 強制アップデート(履歴の書き換え)では機能しません。
  - `allowlist`パターンに一致するブランチのみがプロキシプッシュされます。
- スクリプトは、`$TARGET_REPO`の更新がrefsの更新と見なされ、Gitがそれに関する警告を表示するため、Gitフック検疫環境を回避します。

## Git Fusionを使用したPerforce Helixとのミラー {#mirror-with-perforce-helix-with-git-fusion}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

{{< alert type="warning" >}}

双方向ミラーリングは、永続的な設定として使用しないでください。代替移行アプローチについては、[Perforce Helixからの移行](../../import/perforce.md)を参照してください。

{{< /alert >}}

[Git Fusion](https://www.perforce.com/manuals/git-fusion/#Git-Fusion/section_avy_hyc_gl.html)は、[Perforce Helix](https://www.perforce.com/products)へのGitインターフェースを提供します。GitLabはPerforce Helixインターフェースを使用して、プロジェクトを双方向にミラーできます。オーバーラップするPerforce Helixワークスペースを同時に移行できない場合は、Perforce HelixからGitLabに移行する際に役立ちます。

Perforce Helixでミラーする場合は、保護ブランチのみをミラーしてください。Perforce Helixは、履歴を書き換えるプッシュを拒否します。Git Fusionのパフォーマンス上の制限により、ミラーするブランチの数は最小限にする必要があります。

Git Fusionを使用してPerforce Helixでミラーリングを構成する場合は、次のGit Fusion設定を使用する必要があります:

- `change-pusher`を無効にします。そうしないと、すべてのコミットは、既存のPerforce Helixユーザーまたは`unknown_git`ユーザーにマッピングするのではなく、ミラーリングアカウントによってコミットされたものとして書き換えられます。
- GitLabユーザーがPerforce Helixに存在しない場合は、`unknown_git`ユーザーをコミット作成者として使用します。

## 関連トピック {#related-topics}

- リポジトリのミラーリングに関する[トラブルシューティング](troubleshooting.md)。
- [サーバーフック](../../../../administration/server_hooks.md)
