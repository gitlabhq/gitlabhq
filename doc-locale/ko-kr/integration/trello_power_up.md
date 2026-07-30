---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Trello Power-Ups
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Trello Power-Ups for GitLab을 사용하여 GitLab 머지 리퀘스트를 Trello 카드에 첨부할 수 있습니다.

![GitLab Trello Power-Ups - Trello 카드](img/trello_card_with_gitlab_powerup_v9_4.png)

## Power-Ups 구성 {#configure-power-ups}

Trello 보드에 대해 Power-Ups를 구성하려면:

1. Trello 보드로 이동합니다.
1. **Power-Ups**를 선택하고 **GitLab** 행을 찾습니다.
1. **사용**을 선택합니다.
1. **설정**(톱니바퀴 아이콘)을 선택합니다.
1. **Authorize Account**을 선택합니다.
1. [GitLab API URL](#get-the-api-url)과 [개인 액세스 토큰](../user/profile/personal_access_tokens.md#create-a-personal-access-token)을 **API** 범위로 입력합니다.
1. **저장**을 선택합니다.

## API URL 가져오기 {#get-the-api-url}

API URL은 GitLab 인스턴스 URL의 끝에 `/api/v4`이 추가된 것입니다. 예를 들어 GitLab 인스턴스 URL이 `https://gitlab.com`이면 API URL은 `https://gitlab.com/api/v4`입니다. 인스턴스 URL이 `https://example.com`이면 API URL은 `https://example.com/api/v4`입니다.
