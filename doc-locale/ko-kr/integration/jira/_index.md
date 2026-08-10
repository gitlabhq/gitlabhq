---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 프로젝트를 Jira와 연결하여 두 플랫폼 전체에서 능률적인 개발 워크플로우를 유지합니다. 팀이 이슈 추적을 위해 Jira를 사용하고 개발을 위해 GitLab을 사용할 때, Jira 통합은 계획과 실행 사이의 연결을 만듭니다.

Jira 통합을 사용하면:

- 개발 팀은 컨텍스트 전환 없이 GitLab에서 직접 Jira 이슈에 액세스할 수 있습니다.
- 프로젝트 관리자는 팀이 GitLab에서 작업할 때 Jira에서 개발 진행 상황을 추적할 수 있습니다.
- 개발자가 커밋과 머지 리퀘스트에서 Jira 이슈를 참조할 때 Jira 이슈가 자동으로 업데이트됩니다.
- 팀 멤버는 코드 변경 사항과 Jira 이슈에서 추적한 요구 사항 간의 연결을 발견합니다.
- GitLab의 취약성 결과가 Jira에서 적절한 추적 및 해결을 위한 이슈를 생성합니다.

[Jira 이슈를 GitLab으로 가져올 수 있거나](../../user/import/third_party_systems/jira.md) Jira를 GitLab과 통합하고 두 플랫폼을 계속 함께 사용할 수 있습니다.

## Jira 통합 {#jira-integrations}

GitLab은 두 가지 Jira 통합을 제공합니다. 필요한 기능에 따라 [한 가지 또는 두 가지 통합을 모두 사용할 수 있습니다](#feature-availability).

### Jira 이슈 통합 {#jira-issues-integration}

{{< history >}}

- GitLab 17.6에서 [기능 이름을 Jira 이슈 통합으로 변경했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555).

{{< /history >}}

GitLab에서 개발한 [Jira 이슈 통합](configure.md)을 Jira Cloud, Jira Data Center 또는 Jira Server와 함께 사용할 수 있습니다. 이 통합을 사용하면 다음을 수행할 수 있습니다:

- GitLab에서 직접 Jira 이슈를 보고 검색합니다.
- GitLab 커밋과 머지 리퀘스트에서 Jira 이슈를 ID로 참조합니다.
- 취약성에 대한 Jira 이슈를 생성합니다.

### Jira 개발 패널 {#jira-development-panel}

[Jira 개발 패널](development_panel.md)을 사용하여 [이슈에 대한 GitLab 활동을 볼 수 있으며](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) 관련 브랜치, 커밋 및 머지 리퀘스트가 포함됩니다. Jira 개발 패널을 구성하려면:

- **For Jira Cloud**, GitLab에서 개발하고 유지 관리하는 [Jira Cloud용 GitLab 앱](connect-app.md)을 사용합니다.
- **For Jira Data Center or Jira Server**, Atlassian에서 개발하고 유지 관리하는 [Jira DVCS 커넥터](dvcs/_index.md)를 사용합니다.

## 기능 가용성 {#feature-availability}

이 표는 Jira 이슈 통합 및 Jira 개발 패널에서 사용 가능한 기능을 보여줍니다:

| 기능                                                                                                                                                                                                             | Jira 이슈 통합                                                                                                                                                                | Jira 개발 패널 |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|
| GitLab 커밋 또는 머지 리퀘스트에서 Jira 이슈 ID를 언급하면 Jira 이슈에 대한 링크가 생성됩니다.                                                                                                               | {{< icon name="check-circle" >}} 예                                                                                                                                                   | {{< icon name="dotted-circle" >}} 아니요 |
| GitLab에서 Jira 이슈 ID를 언급하면 Jira 이슈에 GitLab 이슈 또는 머지 리퀘스트가 표시됩니다.                                                                                                                      | {{< icon name="check-circle" >}} 예, GitLab 이슈 또는 머지 리퀘스트 제목이 있는 Jira 댓글이 GitLab으로 연결됩니다. 첫 번째 언급이 Jira 이슈의 **Web links**에도 추가됩니다. | {{< icon name="check-circle" >}} 예, GitLab 머지 리퀘스트는 Jira 이슈의 [개발 패널](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)에 표시됩니다. GitLab 이슈는 개발 패널에 표시되지 않습니다. |
| GitLab 커밋에서 Jira 이슈 ID를 언급하면 Jira 이슈에 커밋 메시지가 표시됩니다.                                                                                                                            | {{< icon name="check-circle" >}} 예, 전체 커밋 메시지가 Jira 이슈에 댓글로 표시되고 **Web links**에 표시됩니다. 각 메시지는 GitLab의 커밋으로 다시 연결됩니다.     | {{< icon name="check-circle" >}} 예, Jira 이슈의 개발 패널에서. [Jira Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)를 사용하여 사용자 정의 댓글을 작성할 수 있습니다. |
| GitLab 브랜치 이름에서 Jira 이슈 ID를 언급하면 Jira 이슈에 브랜치 이름이 표시됩니다.                                                                                                                          | {{< icon name="dotted-circle" >}} 아니요                                                                                                                                                   | {{< icon name="check-circle" >}} 예, Jira 이슈의 개발 패널에서. |
| Jira 이슈에 시간 추적을 추가합니다.                                                                                                                                                                                  | {{< icon name="dotted-circle" >}} 아니요                                                                                                                                                   | {{< icon name="check-circle" >}} 예, Jira Smart Commits 사용. |
| GitLab 커밋 또는 머지 리퀘스트를 사용하여 Jira 이슈를 전환합니다.                                                                                                                                                    | {{< icon name="check-circle" >}} 예, 단일 전환만. 일반적으로 Jira 이슈를 닫는 데 사용됩니다.                                                                                | {{< icon name="check-circle" >}} 예, Jira Smart Commits를 사용하여 Jira 이슈를 임의의 상태로 전환합니다. |
| [Jira 이슈 목록 보기](configure.md#view-jira-issues).                                                                                                                                                        | {{< icon name="check-circle" >}} 예                                                                                                                                                   | {{< icon name="dotted-circle" >}} 아니요 |
| [취약성에 대한 Jira 이슈 생성](configure.md#create-a-jira-issue-for-a-vulnerability).                                                                                                                    | {{< icon name="check-circle" >}} 예                                                                                                                                                   | {{< icon name="dotted-circle" >}} 아니요 |
| Jira 이슈에서 GitLab 브랜치를 생성합니다.                                                                                                                                                                           | {{< icon name="dotted-circle" >}} 아니요                                                                                                                                                   | {{< icon name="check-circle" >}} 예, Jira 이슈의 개발 패널에서. |
| GitLab 머지 리퀘스트, 브랜치 이름 또는 환경에 마지막으로 성공한 배포 이후 브랜치에 대한 마지막 2,000개 커밋 중 하나에서 Jira 이슈 ID를 언급하여 GitLab 배포를 Jira 이슈와 동기화합니다. | {{< icon name="dotted-circle" >}} 아니요                                                                                                                                                   | {{< icon name="check-circle" >}} 예, Jira 이슈의 개발 패널에서. |

## 개인정보보호 고려 사항 {#privacy-considerations}

모든 Jira 이슈 통합은 GitLab 외부와 데이터를 공유합니다. 개인 GitLab 프로젝트를 Jira와 통합하면 개인 데이터가 Jira 프로젝트에 액세스할 수 있는 사용자와 공유됩니다.

[Jira 이슈 통합](configure.md)은 Jira 이슈에 대한 댓글로 GitLab 데이터를 게시합니다. [Jira Cloud용 GitLab 앱](connect-app.md) 및 [Jira DVCS 커넥터](dvcs/_index.md)는 [Jira 개발 패널](development_panel.md)을 통해 GitLab 데이터를 공유합니다. Jira 개발 패널을 사용하면 특정 사용자 그룹 또는 역할에 대한 액세스를 제한할 수 있습니다.

## 관련 항목 {#related-topics}

- [타사 Jira 통합](https://marketplace.atlassian.com/search?product=jira&query=gitlab)
