---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスデスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

この機能は活発な開発は行われていませんが、[コミュニティからのコントリビュート](https://about.gitlab.com/community/contribute/)を歓迎します。この機能がお客様のニーズを満たすかどうかを判断するには、既存のドキュメントを調査するか、[サービスデスクカテゴリの未解決のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=Category%3AService%20Desk&first_page_size=100)を参照して、まだ実施されていない作業について詳しく調査してください。サービスデスクの優先順位を下げるという決定は、作業アイテムフレームワークの構築と拡張に重点を置くために行われました。サービスデスクカテゴリも長期的にその恩恵を受けるでしょう。

サービスデスクを作業アイテムフレームワークに移行する方法については、[エピック10772](https://gitlab.com/groups/gitlab-org/-/epics/10772)を参照してください。

{{< /alert >}}

サービスデスクを使用すると、顧客はバグレポート、機能リクエスト、または一般的なフィードバックをメールで送信できます。サービスデスクは一意のメールアドレスを提供するので、顧客は独自のGitLabアカウントを必要としません。

サービスデスクのメールは、新しいイシューとしてGitLabプロジェクトに作成されます。チームはプロジェクトから直接応答できますが、顧客はメールのみを介してスレッドを操作します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>ビデオの概要については、[GitLabサービスデスクの紹介（GitLab 16.7）](https://www.youtube.com/watch?v=LDVQXv3I5rI)をご覧ください。
<!-- Video published on 2023-12-19 -->

## サービスデスクのワークフロー {#service-desk-workflow}

たとえば、iOSまたはAndroid向けのゲームを開発すると仮定しましょう。コードベースはGitLabインスタンスでホストされ、GitLab CI/CDでビルドおよびデプロイされます。

サービスデスクの仕組みは次のとおりです:

1. プロジェクト固有のメールアドレスを有料顧客に提供します。顧客はアプリケーションから直接メールを送信できます。
1. 顧客が送信する各メールは、適切なプロジェクトにイシューを作成します。
1. チームメンバーは、サービスデスクのイシュートラッカーにアクセスして、新しいサポートリクエストを確認し、関連するイシュー内で応答できます。
1. チームは顧客とコミュニケーションを取り、リクエストを理解します。
1. チームは顧客の問題を解決するためのコードの実装に取り組み始めます。
1. チームが実装を完了すると、マージリクエストがマージされ、イシューが自動的に閉じられます。

その間:

- 顧客はGitLabインスタンスにアクセスしなくても、メールを介してチームと完全にやり取りします。
- チームはGitLabを離れたり、（インテグレーションをセットアップしたり）顧客にフォローアップしたりする必要がないため、時間を節約できます。

## 関連トピック {#related-topics}

- [サービスデスクを設定する](configure.md)
  - [プロジェクトのセキュリティを改善する](configure.md#improve-your-projects-security)
  - [外部参加者に送信されるメールをカスタマイズする](configure.md#customize-emails-sent-to-external-participants)
  - [サービスデスクチケットにカスタムテンプレートを使用する](configure.md#use-a-custom-template-for-service-desk-tickets)
  - [サポートボットユーザー](configure.md#support-bot-user)
  - [デフォルトのチケットの表示レベル](configure.md#default-ticket-visibility)
  - [外部参加者がコメントしたときにイシューを再度開く](configure.md#reopen-issues-when-an-external-participant-comments)
  - [カスタムメールアドレス](configure.md#custom-email-address)
  - [追加のサービスデスクエイリアスメールを使用する](configure.md#use-an-additional-service-desk-alias-email)
  - [マルチノード環境でのメール取り込みを設定する](configure.md#configure-email-ingestion-in-multi-node-environments)
- [サービスデスクを使用する](using_service_desk.md)
  - [(イシュー作成者)としてのエンドユーザー](using_service_desk.md#as-an-end-user-issue-creator)
  - [イシューへの応答者として](using_service_desk.md#as-a-responder-to-the-issue)
  - [メールの内容と書式](using_service_desk.md#email-contents-and-formatting)
  - [通常のイシューをサービスデスクチケットに変換する](using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket)
  - [プライバシーに関する考慮事項](using_service_desk.md#privacy-considerations)
- [外部参加者](external_participants.md)
  - [サービスデスクチケット](external_participants.md#service-desk-tickets)
  - [外部参加者として](external_participants.md#as-an-external-participant)
  - [GitLabユーザーとして](external_participants.md#as-a-gitlab-user)

## サービスデスクのトラブルシューティング {#troubleshooting-service-desk}

### メールがサービスデスクに送信されてもイシューが作成されない {#emails-to-service-desk-do-not-create-issues}

- メールに[GitLabが無視するメールヘッダー](../../../administration/incoming_email.md#rejected-headers)のいずれかが含まれているため、無視される可能性があります。
- メールがプロジェクト固有のサービスデスクアドレスに転送されるため、送信者のメールドメインが厳密なDKIMルールを使用しており、検証に失敗した場合、メールがドロップされる可能性があります。メールヘッダーにある一般的なDKIM障害メッセージは、次のようになります:

  ```plaintext
  dkim=fail (signature did not verify) ... arc=fail
  ```

  障害メッセージの正確な文言は、使用する特定のメールシステムまたはツールによって異なる場合があります。詳細および考えられる解決策については、[DKIM障害に関するこの記事](https://automatedemailwarmup.com/blog/dkim-fail/)も参照してください。

### メール取り込みが16.6.0で機能しない {#email-ingestion-doesnt-work-in-1660}

GitLab Self-Managed `16.6.0`は、`mail_room` (メール取り込み)の起動を妨げるリグレッションを導入しました。サービスデスクおよびその他のメールによる返信機能は動作しません。[イシュー432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257)は、この問題の修正を追跡します。

この問題を修正するパッチを適用するには、GitLabインスタンスで次のコマンドを実行して、影響を受けるファイルをパッチします:

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
