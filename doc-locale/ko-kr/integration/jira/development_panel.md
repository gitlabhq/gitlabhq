---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira 개발 패널
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Jira 개발 패널을 사용하여 Jira에서 직접 Jira 이슈에 대한 GitLab 활동을 볼 수 있습니다. Jira 개발 패널을 설정하려면:

- **For Jira Cloud**의 경우 GitLab에서 개발하고 유지 관리하는 [GitLab for Jira Cloud 앱](connect-app.md)을 사용합니다.
- **For Jira Data Center or Jira Server**의 경우 Atlassian에서 개발하고 유지 관리하는 [Jira DVCS 커넥터](dvcs/_index.md)를 사용합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [Jira 개발 패널 통합](https://www.youtube.com/watch?v=VjVTOmMl85M)을 참조하세요.

## 기능 가용성 {#feature-availability}

{{< history >}}

- 브랜치 삭제 기능이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148712)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `jira_connect_remove_branches`로 명명되었습니다. 기본적으로 비활성화되었습니다.
- 브랜치 삭제 기능이 GitLab 17.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158224)하게 되었습니다. `jira_connect_remove_branches` 기능 플래그가 제거되었습니다.

{{< /history >}}

이 표는 Jira DVCS 커넥터 및 GitLab for Jira Cloud 앱에서 사용 가능한 기능을 보여줍니다:

| 기능                              | Jira DVCS 커넥터 | Jira Cloud 앱용 GitLab |
|:-------------------------------------|:--------------------|:--------------------------|
| Smart Commits                        | {{< yes >}}         | {{< yes >}}               |
| 머지 리퀘스트 동기화                  | {{< yes >}}         | {{< yes >}}               |
| 브랜치 동기화                        | {{< yes >}}         | {{< yes >}}               |
| 커밋 동기화                         | {{< yes >}}         | {{< yes >}}               |
| 기존 데이터 동기화                   | {{< yes >}}         | {{< yes >}} ([Jira로 동기화된 GitLab 데이터](connect-app.md#gitlab-data-synced-to-jira) 참조) |
| 빌드 동기화                          | {{< no >}}          | {{< yes >}}               |
| 배포 동기화                     | {{< no >}}          | {{< yes >}}               |
| 기능 플래그 동기화                   | {{< no >}}          | {{< yes >}}               |
| 동기화 간격                        | 최대 60분    | 실시간                 |
| 브랜치 삭제                      | {{< no >}}          | {{< yes >}}               |
| 브랜치에서 머지 리퀘스트 생성 | {{< yes >}}         | {{< yes >}}               |
| Jira 이슈에서 브랜치 생성    | {{< no >}}          | {{< yes >}}               |

## GitLab의 연결된 프로젝트 {#connected-projects-in-gitlab}

Jira 개발 패널은 Jira 인스턴스와 모든 해당 프로젝트를 다음에 연결합니다:

- **[GitLab for Jira Cloud 앱](connect-app.md)의 경우**, 연결된 GitLab 그룹 또는 서브그룹과 해당 프로젝트
- **[Jira DVCS 커넥터](dvcs/_index.md)의 경우**, 연결된 GitLab 그룹, 서브그룹 또는 개인 네임스페이스와 해당 프로젝트

## 개발 패널에 표시되는 정보 {#information-displayed-in-the-development-panel}

Jira 개발 패널에서 GitLab ID로 Jira 이슈를 참조하여 [Jira 이슈에 대한 GitLab 활동을 볼](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) 수 있습니다. 개발 패널에 표시되는 정보는 GitLab에서 Jira 이슈 ID를 언급하는 위치에 따라 다릅니다.

[GitLab for Jira Cloud 앱](connect-app.md)의 경우 다음 정보가 표시됩니다.

| GitLab: Jira 이슈 ID를 언급하는 위치 | Jira 개발 패널: 표시되는 정보 |
|---------------------------------------------|-------------------------------------------------------|
| 머지 리퀘스트 제목 또는 설명          | 머지 리퀘스트로의 링크<br>배포로의 링크<br>머지 리퀘스트 제목을 통한 파이프라인으로의 링크<br>머지 리퀘스트 설명을 통한 파이프라인으로의 링크 (GitLab 15.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/390888)됨)<br>브랜치로의 링크 (GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/354373)됨)<br>검토자 정보 및 승인 상태 (GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)됨) |
| 브랜치 이름                                 | 브랜치로의 링크<br>배포로의 링크          |
| 커밋 메시지                              | 커밋으로의 링크<br>환경으로의 마지막 성공적인 배포 이후 최대 2,000개 커밋에서 배포로의 링크 <sup>1</sup> <sup>2</sup> |
| [Jira Smart Commit](#jira-smart-commits)    | 사용자 정의 의견, 기록된 시간 또는 워크플로우 전환   |

**각주**:

1. GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `jira_deployment_issue_keys`로 명명되었습니다. 기본적으로 활성화되었습니다.
1. GitLab 16.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/415025)합니다. `jira_deployment_issue_keys` 기능 플래그가 제거되었습니다.

## Jira Smart Commits {#jira-smart-commits}

전제 조건:

- 동일한 이메일 주소 또는 사용자 이름을 가진 GitLab 및 Jira 사용자 계정이 있어야 합니다.
- 명령어는 커밋 메시지의 첫 번째 줄에 있어야 합니다.
- 커밋 메시지는 한 줄 이상으로 확장되지 않아야 합니다.

Jira Smart Commits는 Jira 이슈를 처리하기 위한 특수 명령어입니다. 이 명령어를 사용하면 GitLab을 통해 다음을 수행할 수 있습니다:

- Jira 이슈에 사용자 정의 의견을 추가합니다.
- Jira 이슈에 대해 시간을 기록합니다.
- Jira 이슈를 프로젝트 워크플로우에 정의된 모든 상태로 전환합니다.

Smart Commits는 다음 구문을 따라야 합니다:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

단일 커밋에서 하나 이상의 명령어를 실행할 수 있습니다.

### Smart Commit 구문 {#smart-commit-syntax}

| 명령어                                        | 구문                                                       |
|-------------------------------------------------|--------------------------------------------------------------|
| 의견 추가                                   | `KEY-123 #comment Bug is fixed`                              |
| 시간 기록                                        | `KEY-123 #time 2w 4d 10h 52m Tracking work time`             |
| 이슈 닫기                                  | `KEY-123 #close Closing issue`                               |
| 시간 기록 및 이슈 닫기                     | `KEY-123 #time 2d 5h #close`                                 |
| 의견 추가 및 **In-progress**로 전환 | `KEY-123 #comment Started working on the issue #in-progress` |

Smart Commits 작동 방식 및 사용 가능한 명령어에 대한 자세한 내용은 다음을 참조하세요:

- [Smart Commits로 이슈 처리](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
- [Smart Commits 사용](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)

## Jira 배포 {#jira-deployments}

Jira 배포를 사용하여 Jira에서 직접 소프트웨어 릴리스의 진행 상황을 추적하고 시각화할 수 있습니다.

GitLab은 다음 경우 환경 및 배포에 대한 정보를 Jira에 보냅니다:

- 프로젝트의 `.gitlab-ci.yml` 파일에 [`environment`](../../ci/yaml/_index.md#environment) 키워드가 포함되어 있습니다.
- Jira 이슈 ID가 [GitLab의 특정 부분에 언급](#information-displayed-in-the-development-panel)되고 파이프라인이 트리거됩니다.

자세한 내용은 [환경 및 배포](../../ci/environments/_index.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [Jira Server의 개발 패널 문제 해결](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html)
