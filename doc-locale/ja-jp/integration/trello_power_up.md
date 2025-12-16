---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Trello Power-Ups
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

TrelloカードにGitLabのマージリクエストを添付するために、Trello Power-Ups for GitLabを使用できます。

![GitLab Trello Power-Ups - Trelloカード](img/trello_card_with_gitlab_powerup_v9_4.png)

## Power-Upsの設定 {#configure-power-ups}

TrelloボードのPower-Upsを設定するには、次の手順に従います:

1. Trelloボードに移動します。
1. **Power-Ups**を選択し、**GitLab**の行を見つけます。
1. **有効**を選択します。
1. **設定**を選択します。
1. **Authorize Account**（アカウント認証）を選択します。
1. [GitLab API URL](#get-the-api-url)と、**API**スコープを持つ[パーソナルアクセストークン](../user/profile/personal_access_tokens.md#create-a-personal-access-token)を入力します。
1. **保存**を選択します。

## API URLを取得する {#get-the-api-url}

API URLは、`/api/v4`がURLの末尾に追加されたGitLabインスタンスのURLです。たとえば、GitLabインスタンスのURLが`https://gitlab.com`の場合、API URLは`https://gitlab.com/api/v4`です。インスタンスURLが`https://example.com`の場合、API URLは`https://example.com/api/v4`です。
