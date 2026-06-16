---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리포지토리 일관성 검사
---

Gitaly는 리포지토리 일관성 검사를 실행합니다:

- 리포지토리 검사를 트리거할 때
- 변경 사항이 미러링된 리포지토리에서 가져올 때
- 사용자가 변경 사항을 리포지토리에 푸시할 때

이러한 일관성 검사는 리포지토리에 필요한 모든 개체가 있는지, 그리고 이러한 개체가 유효한 개체인지 확인합니다. 다음과 같이 분류할 수 있습니다:

- 리포지토리가 손상되지 않도록 하는 기본 검사 여기에는 연결성 검사와 개체를 구문 분석할 수 있는 검사가 포함됩니다.
- Git의 과거 보안 관련 버그를 악용하기에 적합한 개체를 인식하는 보안 검사
- 모든 개체 메타데이터가 유효한지 확인하는 외관 검사 이전 Git 버전 및 다른 Git 구현에서 유효하지 않은 메타데이터가 있는 개체를 생성했을 수 있지만, 최신 버전에서는 이러한 형식이 잘못된 개체를 해석할 수 있습니다.

일관성 검사에 실패한 형식이 잘못된 개체를 제거하려면 리포지토리 기록을 다시 작성해야 하는데, 이는 종종 수행할 수 없습니다. 따라서 Gitaly는 기본적으로 [리포지토리 일관성에 부정적인 영향을 주지 않는 외관 문제 범위에 대한 일관성 검사를 비활성화합니다](#disabled-checks)

기본적으로 Gitaly는 기본 또는 보안 관련 검사를 비활성화하지 않으므로 Git 클라이언트에서 알려진 취약점을 트리거할 수 있는 개체를 배포하지 않습니다. 또한 프로젝트에 악의적인 의도가 없는 경우에도 이러한 개체를 포함하는 리포지토리를 가져오는 기능을 제한합니다.

## 리포지토리 일관성 검사 재정의 {#override-repository-consistency-checks}

인스턴스 관리자는 일관성 검사를 통과하지 못하는 리포지토리를 처리해야 하는 경우 일관성 검사를 재정의할 수 있습니다.

Linux 패키지 설치의 경우 `/etc/gitlab/gitlab.rb`을 편집하고 다음 키를 설정합니다(이 예제에서는 이전 커밋의 잘못된 이메일 헤더를 허용하고 `hasDotgit` 및 `gitmodulesUrl` 일관성 검사를 비활성화하려면):

```ruby
ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      # Allow bad email headers in old commits
      # (Populate a file with one unabbreviated SHA-1 per line.
      #  See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList)
      { key: "fsck.skipList", value: ignored_blobs },
      { key: "fetch.fsck.skipList", value: ignored_blobs },
      { key: "receive.fsck.skipList", value: ignored_blobs },
      { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },

      # Ignore specific consistency checks
      # See https://git-scm.com/docs/git-fsck.html#_fsck_messages
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
      { key: "fsck.gitmodulesUrl", value: "ignore" },
      { key: "fetch.fsck.gitmodulesUrl", value: "ignore" },
    ],
  },
}
```

자체 컴파일된 설치의 경우 Gitaly 구성(`gitaly.toml`)을 편집하여 동등한 작업을 수행합니다:

```toml
[[git.config]]
key = "fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fetch.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "receive.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fetch.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "receive.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fsck.gitmodulesUrl"
value = "ignore"

[[git.config]]
key = "fetch.fsck.gitmodulesUrl"
value = "ignore"

[[git.config]]
key = "fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "fetch.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "receive.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"
```

## 비활성화된 검사 {#disabled-checks}

Gitaly가 보안이나 Gitaly 클라이언트에 영향을 주지 않는 특정 형식이 잘못된 특성이 있는 리포지토리를 계속 사용할 수 있도록 하기 위해 Gitaly는 기본적으로 [외관 검사의 하위 집합](https://gitlab.com/gitlab-org/gitaly/-/blob/79643229c351d39a7b16d90b6023ebe5f8108c16/internal/git/command_description.go#L483-524)을 비활성화합니다.

전체 일관성 검사 목록을 보려면 [Git 문서](https://git-scm.com/docs/git-fsck#_fsck_messages)를 참조하세요.

### `badTimezone` {#badtimezone}

`badTimezone` 검사는 사용자가 유효하지 않은 타임존으로 커밋을 생성하게 한 Git의 버그가 있었기 때문에 비활성화됩니다. 결과적으로 일부 Git 로그에는 사양과 일치하지 않는 커밋이 포함됩니다. Gitaly는 기본적으로 수신된 `packfiles`에서 `fsck`을 실행하므로 이러한 커밋을 포함하는 모든 푸시는 거부됩니다.

### `missingSpaceBeforeDate` {#missingspacebeforedate}

`missingSpaceBeforeDate` 검사는 서명이 메일과 날짜 사이의 공백이 없거나 날짜가 완전히 누락되었을 때 `git-fsck(1)`가 실패하기 때문에 비활성화됩니다. 이는 Git 클라이언트의 오작동을 포함하여 다양한 문제로 인해 발생할 수 있습니다.

### `zeroPaddedFilemode` {#zeropaddedfilemode}

`zeroPaddedFilemode` 검사는 이전 Git 버전에서 일부 파일 모드를 0으로 패딩하기 위해 비활성화됩니다. 예를 들어, `40000`의 파일 모드 대신 트리 개체는 파일 모드를 `040000`로 인코딩했을 것입니다.
