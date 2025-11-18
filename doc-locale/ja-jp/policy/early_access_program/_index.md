---
stage: none
group: Contributor Success
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GitLab早期アクセスプログラム
---

{{< alert type="note" >}}

最終ステータスの更新：2024-10-02

{{< /alert >}}

これらの機能は本番環境での使用に対応していない可能性があり、GitLabの[試験的またはベータ](../development_stages_support.md)版ポリシーに従います。

## GitLab早期アクセスプログラムに含まれる機能 {#features-included-in-the-gitlab-early-access-program}

| 名前                                                                                                                                        | ステータス                                                    | 追加日 | フィードバックを提供する |
|---------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|---------------|------------------|
| [GitLab Duo脆弱性の解決](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                    | [ベータ](../development_stages_support.md#beta)             | 2024-10-02    | [フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/476553) |
| [GitLab Duoイシュー説明の生成](../../user/project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | [実験的機能](../development_stages_support.md#experiment) | 2024-10-02    | [フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/409844) |
| [K8s上のGitaly](../../administration/gitaly/kubernetes.md)                                                                                  | [ベータ](../development_stages_support.md#beta)             | 2025-02-25    | [フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/520544) |

有料機能を使用したいが、サブスクリプションをお持ちでない場合[無料トライアルをリクエストしてください](https://about.gitlab.com/free-trial/)。

## プログラムに機能を追加 {#add-a-feature-to-the-program}

マージリクエストを作成し、[前の表](#features-included-in-the-gitlab-early-access-program)に機能を追加します。`@nick_vh`と`@knockfog-ext`をレビュアーとして割り当てます。さらに、詳細については、`#developer-relations-early-access-program` Slackチャンネルにメッセージを投稿してください。

<!--
## Features previously enrolled

| Name                                                                              | Status     | Enrolled at   | Removed at   |
|-----------------------------------------------------------------------------------|------------|---------------| -------------|
|                                                                                   |            |               |              |
-->
