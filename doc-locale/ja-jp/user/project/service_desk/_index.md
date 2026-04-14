---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: サービスデスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

> [!note]
> この機能は現在活発に開発されていませんが、[コミュニティからの貢献](https://about.gitlab.com/community/contribute/)は歓迎されています。既存のドキュメントを確認するか、[サービスデスクカテゴリのオープンなイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=Category%3AService%20Desk&first_page_size=100)を参照して、現状の機能がニーズを満たすかどうかを判断し、まだ行われていない作業について学習してください。サービスデスクのカテゴリも長期的に利益を得る作業アイテムフレームワークの構築と拡張に注力するため、サービスデスクの優先順位を下げる決定がなされました。
>
> サービスデスクを作業アイテムフレームワークに移行するための情報については、[エピック10772](https://gitlab.com/groups/gitlab-org/-/epics/10772)を参照してください。

サービスデスクを使用すると、顧客はバグ報告、機能リクエスト、または一般的なフィードバックをメールで送信できます。サービスデスクは固有のメールアドレスを提供するため、顧客は独自のGitLabアカウントを必要としません。

サービスデスクのメールは、新しいチケットとしてGitLabプロジェクトで作成されます。お客様はメールのみでスレッドとやり取りしますが、チームはプロジェクトから直接返信できます。

<i class="fa-youtube-play" aria-hidden="true"></i>ビデオ概要については、[GitLabサービスデスクの紹介 (GitLab 16.7)](https://www.youtube.com/watch?v=LDVQXv3I5rI)を参照してください。
<!-- Video published on 2023-12-19 -->

## サービスデスクワークフロー {#service-desk-workflow}

例えば、iOSまたはAndroid向けゲームを開発していると仮定します。コードベースはGitLabインスタンスでホストされ、GitLab CI/CDでビルドおよびデプロイされます。

サービスデスクの仕組みは次のとおりです:

1. プロジェクト固有のメールアドレスを支払顧客に提供すると、彼らはアプリケーションから直接メールを送信できます。
1. 彼らが送信する各メールは、適切なプロジェクトにチケットを作成します。
1. チームメンバーはサービスデスクチケットトラッカーにアクセスし、そこで新しいサポートリクエストを確認し、関連するチケット内で返信できます。
1. チームは顧客とコミュニケーションを取り、リクエストを理解します。
1. チームは顧客の問題を解決するためのコードの実装作業を開始します。
1. チームが実装を完了すると、マージリクエストがマージされ、チケットは自動的にクローズされます。

一方:

- 顧客はGitLabインスタンスへのアクセスを必要とせずに、完全にメールを通じてチームとやり取りします。
- チームは、顧客とのフォローアップのためにGitLabを離れる（またはインテグレーションを設定する）必要がないため、時間を節約できます。

## 関連トピック {#related-topics}

- [サービスデスクを設定する](configure.md)
  - [プロジェクトのセキュリティを向上させる](configure.md#improve-your-projects-security)
  - [外部参加者に送信されるメールをカスタマイズする](configure.md#customize-emails-sent-to-external-participants)
  - [サービスデスクチケットにカスタムテンプレートを使用する](configure.md#use-a-custom-template-for-service-desk-tickets)
  - [サポートボットユーザー](configure.md#support-bot-user)
  - [デフォルトチケットの表示レベル](configure.md#default-ticket-visibility)
  - [外部参加者がコメントしたときにチケットを再オープンする](configure.md#reopen-tickets-when-an-external-participant-comments)
  - [カスタムメールアドレス](configure.md#custom-email-address)
  - [追加のサービスデスクエイリアスメールを使用する](configure.md#use-an-additional-service-desk-alias-email)
  - [マルチノード環境でのメールの取り込みを設定する](configure.md#configure-email-ingestion-in-multi-node-environments)
- [サービスデスクを使用する](using_service_desk.md)
  - [エンドユーザーとして (チケット作成者)](using_service_desk.md#as-an-end-user-ticket-creator)
  - [チケットへの応答者として](using_service_desk.md#as-a-responder-to-the-ticket)
  - [メールの内容と書式設定](using_service_desk.md#email-contents-and-formatting)
  - [通常のイシューをサービスデスクチケットに変換する](using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket)
  - [プライバシーに関する考慮事項](using_service_desk.md#privacy-considerations)
- [外部参加者](external_participants.md)
  - [サービスデスクチケット](external_participants.md#service-desk-tickets)
  - [外部参加者として](external_participants.md#as-an-external-participant)
  - [GitLabユーザーとして](external_participants.md#as-a-gitlab-user)

## サービスデスクのトラブルシューティング {#troubleshooting-service-desk}

### サービスデスクへのメールでチケットが作成されない {#emails-to-service-desk-do-not-create-tickets}

- お使いのメールにGitLabが無視する[メールヘッダー](../../../administration/incoming_email.md#rejected-headers)のいずれかが含まれているため、無視される可能性があります。
- 送信者のメールドメインが厳格なDKIMルールを使用しており、プロジェクト固有のサービスデスクアドレスへのメール転送により検証失敗が発生した場合、メールが破棄されることがあります。メールヘッダーにある典型的なDKIM失敗メッセージは次のようになります:

  ```plaintext
  dkim=fail (signature did not verify) ... arc=fail
  ```

  失敗メッセージの正確な文言は、使用されている特定のメールシステムやツールによって異なる場合があります。詳細および潜在的な解決策については、[DKIMの失敗に関するこの記事](https://automatedemailwarmup.com/blog/dkim-fail/)も参照してください。

### メールの取り込みが16.6.0で動作しない {#email-ingestion-doesnt-work-in-1660}

GitLab Self-Managed `16.6.0`で、`mail_room`（メールの取り込み）の開始を妨げるリグレッションが導入されました。サービスデスクやその他のメール返信機能が動作しません。[イシュー432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257)はこの問題の解決を追跡しています。

回避策は、影響を受けるファイルをパッチするために、GitLabインストールで次のコマンドを実行することです:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< /tabs >}}
