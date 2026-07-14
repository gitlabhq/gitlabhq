---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 기본 Git 작업
description: 리포지토리를 관리하기 위한 기본 Git 작업을 배우세요.
---

기본 Git 작업은 Git 리포지토리를 관리하고 코드를 변경하는 데 도움이 됩니다. 다음과 같은 이점을 제공합니다.

- 버전 관리: 프로젝트 기록을 유지하여 변경 사항을 추적하고 필요한 경우 이전 버전으로 되돌릅니다.
- 협업: 협업을 활성화하고 코드 공유 및 동시 작업을 더욱 용이하게 합니다.
- 조직: 브랜치 및 머지 리퀘스트를 사용하여 작업을 조직하고 관리합니다.
- 코드 품질: 머지 리퀘스트를 통한 코드 검토를 용이하게 하고 코드 품질 및 일관성을 유지하는 데 도움이 됩니다.
- 백업 및 복구: 원격 리포지토리에 변경 사항을 푸시하여 작업이 백업되고 복구 가능한 상태를 유지합니다.

Git 작업을 효과적으로 사용하려면 리포지토리, 브랜치, 커밋, 머지 리퀘스트 같은 핵심 개념을 이해하는 것이 중요합니다. 자세한 내용은 [Git 시작하기](get_started.md)를 참조하세요.

자주 사용되는 Git 명령어에 대한 자세한 내용은 [Git 명령어](commands.md)를 참조하세요.

## 프로젝트 생성 {#create-a-project}

`git push` 명령어는 로컬 리포지토리의 변경 사항을 원격 리포지토리로 전송합니다. 로컬 리포지토리에서 프로젝트를 생성하거나 기존 리포지토리를 가져올 수 있습니다. 리포지토리를 추가한 후 GitLab은 선택한 네임스페이스에 프로젝트를 생성합니다. 자세한 내용은 [프로젝트 생성](project.md)을 참조하세요.

## 리포지토리 복제 {#clone-a-repository}

`git clone` 명령어는 원격 리포지토리의 복사본을 컴퓨터에 생성합니다. 로컬에서 코드를 작업하고 변경 사항을 원격 리포지토리로 푸시할 수 있습니다. 자세한 내용은 [Git 리포지토리 복제](clone.md)를 참조하세요.

## 브랜치 생성 {#create-a-branch}

`git checkout -b <name-of-branch>` 명령어는 리포지토리에 새로운 브랜치를 생성합니다. 브랜치는 기본 브랜치에 영향을 주지 않으면서 수정할 수 있는 리포지토리의 파일 복사본입니다. 자세한 내용은 [브랜치 생성](branch.md)을 참조하세요.

## 단계, 커밋, 푸시 변경 사항 {#stage-commit-and-push-changes}

`git add`, `git commit`, `git push` 명령어는 원격 리포지토리를 변경 사항으로 업데이트합니다. Git은 체크아웃된 브랜치의 최신 버전에 대해 변경 사항을 추적합니다. 자세한 내용은 [단계, 커밋, 푸시 변경 사항](commit.md)을 참조하세요.

## 변경 사항 스태시 {#stash-changes}

`git stash` 명령어는 즉시 커밋하지 않으려는 변경 사항을 임시로 저장합니다. 불완전한 변경 사항을 커밋하지 않고도 브랜치를 전환하거나 다른 작업을 수행할 수 있습니다. 자세한 내용은 [변경 사항 스태시](stash.md)를 참조하세요.

## 브랜치에 파일 추가 {#add-files-to-a-branch}

`git add <filename>` 명령어는 Git 리포지토리 또는 브랜치에 파일을 추가합니다. 새 파일을 추가하거나 기존 파일을 수정하거나 파일을 삭제할 수 있습니다. 자세한 내용은 [브랜치에 파일 추가](add_files.md)를 참조하세요.

## 머지 리퀘스트 {#merge-requests}

머지 리퀘스트는 한 브랜치의 변경 사항을 다른 브랜치로 병합하도록 요청하는 것입니다. 머지 리퀘스트는 협업하고 코드 변경 사항을 검토할 수 있는 방법을 제공합니다. 자세한 내용은 [머지 리퀘스트](../../user/project/merge_requests/_index.md) 및 [브랜치 병합](merge.md)을 참조하세요.

## 포크 업데이트 {#update-your-fork}

포크는 선택한 네임스페이스에서 생성하는 리포지토리와 모든 브랜치의 개인 복사본입니다. 자신의 포크에서 변경 사항을 만들고 `git push`을(를) 사용하여 제출할 수 있습니다. 자세한 내용은 [포크 업데이트](forks.md)를 참조하세요.

## 관련 항목 {#related-topics}

- [Git 시작하기](get_started.md)
  - [Git 설치](how_to_install_git/_index.md)
  - [일반적인 Git 명령어](commands.md)
- [고급 작업](advanced.md)
- [Git 문제 해결](troubleshooting_git.md)
- [Git 치트 시트](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)
