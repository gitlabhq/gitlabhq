---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 업적
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113156)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)인 `achievements`를 사용합니다. 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 [GitLab.com, GitLab Self-Managed, GitLab Dedicated에 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200774)되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

업적은 GitLab에서 사용자의 활동에 대해 보상하는 방법입니다. 네임스페이스 유지보수자 또는 소유자로서 특정 기여에 대한 사용자 정의 업적을 만들 수 있습니다. 정의된 조건에 따라 사용자에게 이러한 업적을 수여하거나 철회할 수 있습니다.

사용자는 프로필에서 다양한 프로젝트 또는 그룹에 대한 기여를 강조하기 위해 업적을 수집할 수 있습니다. 업적은 이름, 설명, 아바타로 구성됩니다.

![사용자 프로필 페이지의 업적](img/user_profile_achievements_v15_11.png)

업적은 사용자가 소유한 것으로 간주됩니다. 업적을 생성한 네임스페이스의 공개 설정에 관계없이 표시됩니다.

계획된 작업에 대한 자세한 내용은 [에픽 9429](https://gitlab.com/groups/gitlab-org/-/epics/9429)를 참조하세요. 에픽에 댓글을 남겨 사용 사례를 알려주세요.

## 업적 유형 {#types-of-achievement}

프로그래밍 방식으로는 업적을 생성, 수여, 철회 또는 삭제하는 방법이 하나뿐입니다.

실제로는 수여되는 업적을 다음과 같이 구분할 수 있습니다:

- 한 번만 철회 불가능합니다. 예를 들어, "첫 기여 병합" 업적이 있습니다.
- 한 번만 철회 가능합니다. 예를 들어, "핵심 팀 멤버" 업적이 있습니다.
- 여러 번입니다. 예를 들어, "월간 기여자" 업적이 있습니다.

## 그룹 업적 보기 {#view-group-achievements}

그룹의 사용 가능한 모든 업적과 수여된 업적을 보려면:

- `https://gitlab.com/groups/<group-path>/-/achievements`로 이동합니다.

페이지에 업적 목록과 업적을 수여받은 멤버가 표시됩니다.

## 사용자의 업적 보기 {#view-a-users-achievements}

사용자의 프로필 페이지에서 사용자의 업적을 볼 수 있습니다.

전제 조건:

- 사용자 프로필이 공개여야 합니다.

사용자의 업적을 보려면:

1. 사용자의 프로필 페이지로 이동합니다.
1. 사용자의 아바타 아래에서 업적을 확인합니다.
1. 업적의 세부 사항을 보려면 위에 마우스를 올립니다. 다음 정보가 표시됩니다:

   - 업적의 이름
   - 업적의 설명
   - 사용자에게 업적이 수여된 날짜
   - 사용자가 네임스페이스의 멤버이거나 네임스페이스가 공개인 경우 업적을 수여한 네임스페이스

사용자의 업적 목록을 검색하려면 [`user` GraphQL 유형](../../api/graphql/reference/_index.md#user)을 쿼리합니다.

`User.userAchievements` 필드는 선택적 `includeHidden` 매개변수를 허용합니다. `true`로 설정하면 응답에 프로필에서 숨겨진 업적이 포함됩니다. 숨겨진 업적은 다음 경우에만 포함됩니다:

- 요청하는 사용자가 요청된 사용자와 동일합니다.
- 요청하는 사용자가 업적이 속한 그룹에서 유지보수자 또는 소유자 역할을 가지고 있습니다.

```graphql
query {
  user(username: "<username>") {
    userAchievements(includeHidden: true) {
      nodes {
        achievement {
          name
          description
          avatarUrl
          namespace {
            fullPath
            name
          }
        }
      }
    }
  }
}
```

## 업적 생성 {#create-an-achievement}

특정 기여에 대해 수여할 사용자 정의 업적을 만들 수 있습니다.

전제 조건:

- 네임스페이스에 대해 유지보수자 또는 소유자 역할이 있어야 합니다.

업적을 생성하려면:

- UI에서:
  1. [업적 페이지](#view-group-achievements)에서 **새로운 업적**을 선택합니다.
  1. 업적의 이름을 입력합니다.
  1. 선택 사항. 설명을 입력하고 업적의 아바타를 업로드합니다.
  1. **변경 사항 저장**을 선택합니다.

- GraphQL API를 사용하여 [`achievementsCreate` GraphQL 변경](../../api/graphql/reference/_index.md#mutationachievementscreate)을 호출합니다:

  ```graphql
  mutation achievementsCreate($file: Upload!) {
    achievementsCreate(
      input: {
        namespaceId: "gid://gitlab/Namespace/<namespace id>",
        name: "<name>",
        description: "<description>",
        avatar: $file}
    ) {
      errors
      achievement {
        id
        name
        description
        avatarUrl
      }
    }
  }
  ```

  아바타 파일을 제공하려면 `curl`을 사용하여 변경을 호출합니다:

  ```shell
  curl "https://gitlab.com/api/graphql" \
    -H "Authorization: Bearer <your-pat-token>" \
    -H "Content-Type: multipart/form-data" \
    -F operations='{ "query": "mutation ($file: Upload!) { achievementsCreate(input: { namespaceId: \"gid://gitlab/Namespace/<namespace-id>\", name: \"<name>\", description: \"<description>\", avatar: $file }) { achievement { id name description avatarUrl } } }", "variables": { "file": null } }' \
    -F map='{ "0": ["variables.file"] }' \
    -F 0='@/path/to/your/file.jpg'
  ```

  성공하면 응답은 업적 ID를 반환합니다:

  ```shell
  {"data":{"achievementsCreate":{"achievement":{"id":"gid://gitlab/Achievements::Achievement/1","name":"<name>","description":"<description>","avatarUrl":"https://gitlab.com/uploads/-/system/achievements/achievement/avatar/1/file.jpg"}}}}
  ```

## 업적 업데이트 {#update-an-achievement}

언제든지 업적의 이름, 설명, 아바타를 변경할 수 있습니다.

전제 조건:

- 네임스페이스에 대해 유지보수자 또는 소유자 역할이 있어야 합니다.

업적을 업데이트하려면 [`achievementsUpdate` GraphQL 변경](../../api/graphql/reference/_index.md#mutationachievementsupdate)을 호출합니다.

```graphql
mutation achievementsUpdate($file: Upload!) {
  achievementsUpdate(
    input: {
      achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
      name: "<new name>",
      description: "<new description>",
      avatar: $file}
  ) {
    errors
    achievement {
      id
      name
      description
      avatarUrl
    }
  }
}
```

## 업적 수여 {#award-an-achievement}

{{< history >}}

- 받는 사람 승인이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227918)되었습니다.

{{< /history >}}

사용자의 기여를 인정하기 위해 사용자에게 업적을 수여할 수 있습니다. 사용자를 수여한 후 사용자는 업적을 수락할 수 있는 링크가 포함된 이메일 알림을 받습니다. 사용자가 업적을 수락할 때까지 업적은 프로필에 표시되지 않습니다.

수락 링크는 30일 동안 유효합니다. 그 후 [`userAchievementsUpdate` GraphQL 변경](#change-visibility-of-specific-achievements)을 호출하여 업적을 수락합니다.

전제 조건:

- 네임스페이스에 대해 유지보수자 또는 소유자 역할이 있어야 합니다.

사용자에게 업적을 수여하려면 [`achievementsAward` GraphQL 변경](../../api/graphql/reference/_index.md#mutationachievementsaward)을 호출합니다.

```graphql
mutation {
  achievementsAward(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>",
    userId: "gid://gitlab/User/<user id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## 업적 철회 {#revoke-an-achievement}

사용자가 더 이상 수여 기준을 충족하지 않는다고 생각되면 사용자의 업적을 철회할 수 있습니다.

전제 조건:

- 네임스페이스에 대해 유지보수자 또는 소유자 역할이 있어야 합니다.

업적을 철회하려면 [`achievementsRevoke` GraphQL 변경](../../api/graphql/reference/_index.md#mutationachievementsrevoke)을 호출합니다.

```graphql
mutation {
  achievementsRevoke(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
      revokedAt
    }
    errors
  }
}
```

## 수여된 업적 삭제 {#delete-an-awarded-achievement}

실수로 사용자에게 업적을 수여한 경우 삭제할 수 있습니다.

전제 조건:

- 네임스페이스에 대해 소유자 역할이 있어야 합니다.

수여된 업적을 삭제하려면 [`userAchievementsDelete` GraphQL 변경](../../api/graphql/reference/_index.md#mutationuserachievementsdelete)을 호출합니다.

```graphql
mutation {
  userAchievementsDelete(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>" }) {
    userAchievement {
      id
      achievement {
        id
        name
      }
      user {
        id
        username
      }
    }
    errors
  }
}
```

## 업적 삭제 {#delete-an-achievement}

더 이상 필요하지 않은 업적은 삭제할 수 있습니다. 이렇게 하면 업적의 관련된 모든 수여 및 철회된 인스턴스가 삭제됩니다.

전제 조건:

- 네임스페이스에 대해 유지보수자 또는 소유자 역할이 있어야 합니다.

업적을 삭제하려면 [`achievementsDelete` GraphQL 변경](../../api/graphql/reference/_index.md#mutationachievementsdelete)을 호출합니다.

```graphql
mutation {
  achievementsDelete(input: {
    achievementId: "gid://gitlab/Achievements::Achievement/<achievement id>" }) {
    achievement {
      id
      name
    }
    errors
  }
}
```

## 업적 숨기기 {#hide-achievements}

프로필에 업적을 표시하지 않으려면 거절할 수 있습니다. 이렇게 하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. **주요 설정** 섹션에서 **프로필에 업적 표시** 확인란을 선택 해제합니다.
1. **프로필 설정 업데이트**를 선택합니다.

## 특정 업적의 공개 여부 변경 {#change-visibility-of-specific-achievements}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161225)되었습니다.

{{< /history >}}

모든 업적을 프로필에 표시하지 않으려면 특정 업적의 공개 여부를 변경할 수 있습니다.

업적 중 하나를 숨기려면 [`userAchievementsUpdate` GraphQL 변경](../../api/graphql/reference/_index.md#mutationuserachievementsupdate)을 호출합니다.

```graphql
mutation {
  userAchievementsUpdate(input: {
    userAchievementId: "gid://gitlab/Achievements::UserAchievement/<user achievement id>"
    showOnProfile: false
  }) {
    userAchievement {
      id
      showOnProfile
    }
    errors
  }
}
```

업적을 다시 표시하려면 `showOnProfile` 인수에 대해 `true` 값으로 동일한 변경을 호출합니다.

## 업적 재정렬 {#reorder-achievements}

기본적으로 프로필의 업적은 수여 날짜 기준 오름차순으로 표시됩니다.

업적의 순서를 변경하려면 [`userAchievementPrioritiesUpdate` GraphQL 변경](../../api/graphql/reference/_index.md#mutationuserachievementprioritiesupdate)을 우선순위가 지정된 모든 업적의 순서 목록과 함께 호출합니다.

```graphql
mutation {
  userAchievementPrioritiesUpdate(input: {
    userAchievementIds: ["gid://gitlab/Achievements::UserAchievement/<first user achievement id>", "gid://gitlab/Achievements::UserAchievement/<second user achievement id>"],
    }) {
    userAchievements {
      id
      priority
    }
    errors
  }
}
```
