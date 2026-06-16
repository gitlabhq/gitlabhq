---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "프로젝트의 코드를 빌드하고, 추적하며, 전달합니다."
title: 코드 관리 시작하기
---

GitLab은 코드 작성부터 배포까지 전체 소프트웨어 개발 수명 주기를 위한 도구를 제공합니다.

GitLab에서 코드를 만들고 관리하는 방법에 대해 자세히 알아보세요. 이 프로세스에는 코드를 작성하고, 검토를 받으며, 버전 제어로 커밋하고, 시간에 따라 업데이트하는 작업이 포함됩니다.

이 프로세스는 더 큰 워크플로의 일부입니다:

![GitLab DevOps 수명 주기의 Create 스테이지에서 코드를 관리하세요.](img/get_started_code_workflow_v16_11.png)

## 1단계:  리포지토리 만들기 {#step-1-create-a-repository}

프로젝트는 다른 사람들과 협업하고, 이슈를 추적하며, 머지 리퀘스트를 관리하고, CI/CD 파이프라인을 자동화하는 등 많은 작업을 수행하는 중앙집중식 위치입니다.

각 프로젝트에는 소프트웨어 개발 작업과 관련된 코드, 문서 및 기타 파일을 저장할 수 있는 리포지토리가 포함되어 있습니다. 리포지토리의 파일에 대한 변경 사항이 추적되므로 히스토리를 볼 수 있습니다.

리포지토리는 소스 코드의 버전 제어에 중점을 두지만, 프로젝트는 전체 개발 수명 주기를 위한 포괄적인 환경을 제공합니다.

자세한 정보는 [리포지토리 만들기](../project/repository/_index.md#create-a-repository)를 참조하세요.

## 2단계:  코드 작성 {#step-2-write-your-code}

코드를 작성하는 방법과 위치에 대한 많은 옵션이 있습니다.

GitLab UI를 사용하여 브라우저에서 바로 개발할 수 있습니다. 두 가지 옵션이 있습니다:

- 단일 파일을 편집할 수 있는 Web Editor라는 일반 텍스트 편집기입니다.
- 여러 파일을 편집할 수 있는 Web IDE라는 더 많은 기능을 갖춘 편집기입니다.

로컬에서 작업하고 싶으신가요? Git을 사용하여 리포지토리를 컴퓨터에 복제하고 선택한 IDE에서 개발하세요. 그런 다음 GitLab 편집기 확장 프로그램 중 하나를 사용하여 GitLab과의 상호 작용을 지원할 수 있습니다.

처음 두 옵션 중 어느 것도 사용하고 싶지 않으신가요? 원격 개발 환경을 시작하고 클라우드에서 작업하세요.

별도의 워크스페이스를 만들어 개발 환경을 더욱 분할할 수 있습니다. 워크스페이스는 다양한 프로젝트가 서로 간섭하지 않도록 하기 위해 사용하는 별도의 개발 환경입니다.

자세한 정보는 다음을 참조하세요:

- [UI에서 리포지토리의 파일 만들기](../project/repository/_index.md#add-a-file-from-the-ui)
- [Web IDE에서 파일 열기](../project/web_ide/_index.md#from-a-file)
- [워크스페이스로 원격 개발 환경 만들기](../workspace/_index.md)
- [사용 가능한 편집기 확장 프로그램](../../editor_extensions/_index.md)

코드 작성에 대한 다른 도움말은 Code Suggestions를 사용하세요.

## 3단계:  변경 사항 저장 및 GitLab에 푸시 {#step-3-save-changes-and-push-to-gitlab}

변경 사항이 준비되면 GitLab에 커밋하여 팀의 다른 사람들과 공유할 수 있습니다.

변경 사항을 커밋하려면 먼저 복사하세요:

- 로컬 컴퓨터에서 자신의 브랜치로
- GitLab의 원격 컴퓨터에 있는 `default branch`로.

브랜치 간에 파일을 복사하려면 머지 리퀘스트를 만듭니다. 이 작업을 수행하는 방법은 코드를 작성한 위치와 생성하는 데 사용하는 도구에 따라 다릅니다. 하지만 소스 브랜치의 내용을 가져와서 대상 브랜치에 병합할 것을 제안하는 머지 리퀘스트를 만드는 것이 목표입니다.

자세한 정보는 다음을 참조하세요:

- [Git을 사용하여 머지 리퀘스트 만들기](../../tutorials/make_first_git_commit/_index.md)
- [파일을 추가, 편집 또는 업로드할 때 UI를 사용하여 머지 리퀘스트 만들기](../project/merge_requests/creating_merge_requests.md)

## 4단계:  코드 검토 받기 {#step-4-have-the-code-reviewed}

머지 리퀘스트를 만들어 코드베이스에 대한 변경 사항을 제안한 후 제안 사항을 검토 받을 수 있습니다. 코드 검토는 코드 품질과 일관성을 유지하는 데 도움이 됩니다. 또한 팀 구성원 간의 지식 공유의 기회이기도 합니다.

머지 리퀘스트는 제안된 변경 사항과 병합하려는 브랜치 간의 차이를 보여줍니다.

검토자는 변경 사항을 보고 특정 코드 라인에 댓글을 달 수 있습니다. 검토자는 diff에서 직접 변경 사항을 제안할 수도 있습니다.

검토자는 병합 전에 변경 사항을 승인하거나 추가 변경을 요청할 수 있습니다. GitLab은 검토 상태를 추적하고 필요한 승인이 얻어질 때까지 병합을 방지합니다.

조직에는 특정 승인을 요구하거나 특정 작업을 방지하는 보호 규칙이 있을 수 있습니다. 예를 들어 변경하는 파일에 대해 코드 소유자로부터 승인을 받아야 할 수도 있고, 머지 리퀘스트를 병합하기 전에 특정 수의 승인이 필요할 수도 있습니다.

자세한 정보는 다음을 참조하세요:

- [머지 리퀘스트의 검토 요청](../project/merge_requests/reviews/_index.md#request-a-review)
- [머지 리퀘스트에 제안 추가](../project/merge_requests/reviews/suggestions.md#create-suggestions)
- [머지 리퀘스트 승인](../project/merge_requests/approvals/_index.md)
- [코드 소유자](../project/codeowners/_index.md)

## 5단계:  머지 리퀘스트 병합 {#step-5-merge-the-merge-request}

변경 사항을 병합하려면 머지 리퀘스트는 보통 다른 사람으로부터 승인을 받아야 하고 CI/CD 파이프라인을 통과해야 합니다. 요구 사항은 조직마다 다르지만 일반적으로 다음을 보장하는 것이 포함됩니다:

- 코드 변경 사항이 조직의 지침을 준수합니다.
- 커밋 메시지가 명확하고 관련 이슈에 연결됩니다.

보호된 브랜치 및 기타 리포지토리 보호 조치는 직접 병합을 방지하거나 추가 단계를 요구할 수 있습니다. 변경 사항을 병합할 수 없으면 팀에 보호 규칙에 대해 문의하세요.

브랜치를 만든 후 대상 브랜치로 병합하기 전에 다른 사람이 파일을 편집하면 머지 충돌이 발생할 수 있습니다. 병합하려면 먼저 모든 충돌을 해결해야 합니다.

자세한 정보는 다음을 참조하세요:

- [머지 충돌](../project/merge_requests/conflicts.md)
- [병합 방법](../project/merge_requests/methods/_index.md)
- [리포지토리 보호](../project/repository/protect.md)
