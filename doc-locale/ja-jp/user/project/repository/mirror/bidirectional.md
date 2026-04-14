---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 2つのGitリポジトリ間で変更をプッシュおよびプルするための双方向ミラーを作成します。
title: 双方向ミラーリング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

> [!warning]
> 双方向ミラーリングは競合を引き起こす可能性があります。

双方向[ミラーリング](_index.md)は、2つのリポジトリが互いにプルする、およびプッシュするように設定します。いずれのリポジトリもエラーなしで更新できるという保証はありません。

## 双方向ミラーリングにおける競合を減らす {#reduce-conflicts-in-bidirectional-mirroring}

双方向ミラーリングを設定する場合、リポジトリを競合に備えて準備します。競合を減らすように設定し、発生した場合にそれらを解決する方法を設定します:

- [保護ブランチのみをミラーする](_index.md#mirror-only-protected-branches)。いずれかのリモートにあるミラーされたコミットを書き換えると、競合が発生し、ミラーリングが失敗します。
- [両方のリモートでミラーしたいブランチを保護](../branches/protected.md)し、履歴の書き換えによって引き起こされる競合を防ぎます。
- [プッシュイベントWebhook](../../integrations/webhook_events.md#push-events)を使用してミラーリングの遅延を減らします。双方向ミラーリングは、同じブランチにほぼ同時に行われたコミットが競合を引き起こす競合状態を作成します。プッシュイベントWebhookは、競合状態を軽減するのに役立ちます。GitLabからのプッシュミラーリングは、保護ブランチのみをプッシュミラーリングする場合、1分間に1回にレート制限されます。
- [事前受信フックを使用して](#prevent-conflicts-by-using-a-pre-receive-hook)競合を防ぎます。

## すぐにGitLabにプルをトリガーするようにWebhookを設定します {#configure-a-webhook-to-trigger-an-immediate-pull-to-gitlab}

ダウンストリームインスタンス内の[プッシュイベントWebhook](../../integrations/webhook_events.md#push-events)は、変更をより頻繁に同期することで競合状態を減らすのに役立ちます。

前提条件: 

- アップストリームのGitLabインスタンスで、[プッシュ](push.md#set-up-a-push-mirror-to-another-gitlab-instance-with-2fa-activated)および[プル](pull.md)ミラーを設定している必要があります。

ダウンストリームインスタンスでWebhookを作成するには:

1. `API`スコープを持つ[パーソナルアクセストークン](../../../profile/personal_access_tokens.md)を作成します。
1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **Webhooks**を選択します。
1. Webhook **URL**を追加します。これは（この場合）、[プルミラーAPI](../../../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)リクエストを使用して、リポジトリ更新後に即座にプルをトリガーするものです:

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:id/mirror/pull?private_token=<your_access_token>
   ```

1. お使いのトークンを[マスクする](../../integrations/webhooks.md#mask-sensitive-portions-of-webhook-urls)。
1. **Push Events**を選択します。
1. **Add Webhook**を選択します。

インテグレーションをTestするには、**Test**を選択し、GitLabがエラーメッセージを返さないことを確認します。

## 事前受信フックを使用して競合を防ぎます {#prevent-conflicts-by-using-a-pre-receive-hook}

> [!warning]
> このソリューションは、Gitのプッシュ操作のパフォーマンスに悪影響を及ぼします。これは、操作がアップストリームのGitリポジトリにプロキシされるためです。

この設定では、一方のGitリポジトリが信頼できるアップストリームとして機能し、もう一方はダウンストリームとして機能します。このサーバーサイドの`pre-receive`フックは、最初にアップストリームリポジトリにコミットをプッシュした後にのみ、プッシュを受け入れます。このフックをダウンストリームリポジトリにインストールします。

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

- 変更なしでは、お使いのユースケースで機能しない場合があります:
  - ミラーの異なる種類の認証メカニズムは考慮されていません。
  - 強制更新（履歴の書き換え）では機能しません。
  - `allowlist`パターンに一致するブランチのみがプロキシプッシュされます。
- スクリプトは、`$TARGET_REPO`の更新が参照更新と見なされ、Gitがそれについて警告を表示するため、Gitフック検疫環境を回避します。

## 関連トピック {#related-topics}

- リポジトリのミラーリングに関する[トラブルシューティング](troubleshooting.md)。
- [サーバーフックを設定する](../../../../administration/server_hooks.md)
