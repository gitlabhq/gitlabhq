---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: 커밋에서 시크릿 제거'
---

애플리케이션이 외부 리소스를 사용하는 경우 일반적으로 토큰이나 키 같은 시크릿으로 애플리케이션을 인증해야 합니다. 시크릿이 원격 리포지토리에 푸시되면 리포지토리에 액세스할 수 있는 누구나 당신이나 당신의 애플리케이션을 사칭할 수 있습니다. 실수로 시크릿을 커밋한 경우에도 푸시하기 전에 제거할 수 있습니다.

이 튜토리얼에서는 가짜 시크릿을 커밋한 다음 프로젝트에 푸시하기 전에 커밋 이력에서 시크릿을 제거합니다. 시크릿이 리포지토리에 푸시될 때 수행할 작업을 배울 수도 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 이 튜토리얼은 GitLab Unfiltered 비디오 [커밋에서 시크릿 제거](https://www.youtube.com/watch?v=2jBC3uBUlyU)에서 개편되었습니다.
<!-- Video published on 2024-06-12 -->

## 시작하기 전에 {#before-you-begin}

이 튜토리얼을 완료하기 전에 다음이 있는지 확인하세요:

- 테스트 프로젝트입니다. 원하는 프로젝트를 사용할 수 있지만, 이 튜토리얼을 위해 특별히 테스트 프로젝트를 생성하는 것이 좋습니다.
- 명령줄 Git에 대한 기본적인 이해입니다.

## 시크릿 커밋 {#commit-a-secret}

GitLab은 특정 문자, 숫자 및 기호 패턴을 일치시켜 시크릿을 식별합니다. 이러한 패턴은 시크릿 유형을 식별하는 데도 사용됩니다. 예를 들어, 가짜 시크릿 `glpat-12345678901234567890`은 `glpat-` 문자열로 시작하기 때문에 개인 액세스 토큰입니다.

많은 시크릿을 형식으로 식별할 수 있지만 리포지토리에서 작업하는 동안 실수로 시크릿을 커밋할 수 있습니다. 시크릿을 실수로 커밋하는 것을 시뮬레이션해 보겠습니다:

1. 테스트 리포지토리에서 새 브랜치를 체크아웃합니다:

   ```shell
   git checkout -b secret-tutorial
   ```

1. 다음 내용으로 새 텍스트 파일을 생성하고 `-` 앞뒤의 공백을 제거하여 개인 액세스 토큰의 정확한 형식과 일치하도록 합니다:

   ```txt
   fake-secret: glpat - 12345678901234567890
   message: hello, world!
   ```

1. 파일을 브랜치에 커밋합니다:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

이것이 문제입니다: 변경 사항이 푸시되면 텍스트 파일의 개인 액세스 토큰이 유출됩니다! 진행하기 전에 커밋 이력에서 시크릿을 제거해야 합니다.

## 이력에서 시크릿 제거 {#remove-the-secret-from-the-history}

시크릿을 포함하는 유일한 커밋이 Git 이력의 가장 최근 커밋인 경우 이력을 수정하여 제거할 수 있습니다:

1. 텍스트 파일을 열고 가짜 시크릿을 제거합니다:

   ```txt
   fake-secret:
   message: hello, world!
   ```

1. 변경 사항으로 이전 커밋을 덮어씁니다:

   ```shell
   git add .
   git commit --amend
   ```

1. 원격 브랜치에 변경 사항을 푸시합니다:

   ```shell
   git push --force-with-lease
   ```

   커밋 이력이 다시 작성되었기 때문에 일반적인 `git push`이 실패합니다. `--force-with-lease` 플래그는 푸시를 강제로 수행하면서 다른 기여자의 커밋을 덮어쓰는 것으로부터 보호합니다.

시크릿이 파일 및 커밋 이력에서 제거됩니다.

### 여러 커밋 수정 {#amending-multiple-commits}

때로는 추가 커밋을 여러 개 수행한 후에야 시크릿이 추가된 것을 알 수 있습니다. 이런 경우 가장 최근 커밋에서 시크릿을 삭제하는 것만으로는 충분하지 않습니다. 시크릿이 추가된 후의 모든 커밋을 변경해야 합니다:

1. 가짜 시크릿을 파일에 추가하고 브랜치에 커밋합니다.
1. 추가 커밋을 최소 1개 이상 수행합니다. 이력을 검사할 때 다음과 같은 내용이 표시되어야 합니다:

   ```shell
   $ git log
   commit 456def

       Do other things

   commit 123abc

       Add fake secret

   ...
   ```

   시크릿이 커밋 `456def`에서 제거되었더라도 이력에 계속 존재하며 변경 사항이 지금 푸시되면 노출됩니다.
1. 이력을 수정하려면 시크릿을 도입한 커밋에서 대화형 리베이스를 시작합니다:

   ```shell
   git rebase -i 123abc~1
   ```

1. 편집 창에서 시크릿을 포함하는 모든 커밋에 대해 `pick`을 `edit`로 변경합니다:

   ```txt
   edit 456def Do other things
   edit 123abc Add fake secret
   ```

1. 텍스트 파일을 열고 가짜 시크릿을 제거합니다.
1. 변경 사항을 커밋합니다:

   ```shell
   git add .
   git commit --amend
   ```

1. 선택 사항입니다. 시크릿을 삭제할 때 커밋의 유일한 diff를 제거할 수 있습니다. 이런 경우 Git은 다음 메시지를 표시합니다:

   ```shell
   No changes
   You asked to amend the most recent commit, but doing so would make it empty.
   ```

   빈 커밋을 제거합니다:

   ```shell
   git reset HEAD^
   ```

1. 리베이스를 계속합니다:

   ```shell
   git rebase --continue
   ```

1. 다음 커밋에서 시크릿을 제거하고 리베이스를 계속합니다. 리베이스가 완료될 때까지 이 프로세스를 반복합니다:

   ```shell
   Successfully rebased and updated refs/heads/secret-tutorial
   ```

1. 원격 브랜치에 변경 사항을 푸시합니다:

   ```shell
   git push --force-with-lease
   ```

   커밋 이력이 다시 작성되었기 때문에 일반적인 `git push`이 실패합니다. `--force-with-lease` 플래그는 푸시를 강제로 수행하면서 다른 기여자의 커밋을 덮어쓰는 것으로부터 보호합니다.

시크릿이 커밋 이력에서 제거됩니다.

## 시크릿을 푸시할 때 수행할 작업 {#what-to-do-when-you-push-a-secret}

때로는 사람들이 변경 사항에 시크릿이 포함되어 있음을 알기 전에 변경 사항을 푸시합니다. 프로젝트에서 시크릿 푸시 보호가 활성화되어 있으면 푸시가 자동으로 차단되고 위반하는 커밋이 표시됩니다.

그러나 시크릿이 원격 리포지토리에 성공적으로 푸시된 경우 더 이상 안전하지 않으므로 즉시 해지해야 합니다. 시크릿에 접근할 수 있는 사람이 많지 않다고 생각하더라도 교체해야 합니다. 노출된 시크릿은 실질적인 보안 위험입니다.

## 다음 단계 {#next-steps}

애플리케이션 보안을 개선하려면 프로젝트에서 [시크릿 검색](_index.md) 방법 중 최소 1개 이상을 활성화하는 것이 좋습니다.
