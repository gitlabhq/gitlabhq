---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: 시크릿 푸시 보호로 프로젝트 보호하기'
---

애플리케이션이 외부 리소스를 사용하는 경우 일반적으로 토큰이나 키 같은 시크릿으로 애플리케이션을 인증해야 합니다. 시크릿이 원격 리포지토리에 푸시되면 리포지토리에 액세스할 수 있는 누구나 당신이나 당신의 애플리케이션을 사칭할 수 있습니다.

시크릿 푸시 보호를 사용하면, GitLab이 커밋 히스토리에서 시크릿을 감지할 경우 푸시를 차단하여 유출을 방지할 수 있습니다. 시크릿 푸시 보호를 활성화하면 민감한 데이터에 대한 커밋을 검토하는 데 소요되는 시간을 줄이고 유출이 발생했을 때 이를 복구할 수 있습니다.

이 튜토리얼에서는 시크릿 푸시 보호를 구성하고 가짜 시크릿을 커밋하려고 할 때 어떤 일이 발생하는지 확인할 수 있습니다. 거짓 양성을 우회해야 하는 경우를 대비하여 시크릿 푸시 보호를 건너뛰는 방법도 배웁니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 이 튜토리얼은 다음의 GitLab Unfiltered 동영상을 바탕으로 작성되었습니다:

- [시크릿 푸시 보호 소개](https://www.youtube.com/watch?v=SFVuKx3hwNI)
  <!-- Video published on 2024-06-21 -->
- [구성 - 프로젝트에 시크릿 푸시 보호 활성화](https://www.youtube.com/watch?v=t1DJN6Vsmp0)
  <!-- Video published on 2024-06-23 -->
- [시크릿 푸시 보호 건너뛰기](https://www.youtube.com/watch?v=wBAhe_d2DkQ)
  <!-- Video published on 2024-06-04 -->

## 시작하기 전에 {#before-you-begin}

이 튜토리얼을 시작하기 전에 다음을 확인하세요:

- GitLab Ultimate 구독.
- 테스트 프로젝트입니다. 원하는 프로젝트를 사용할 수 있지만, 이 튜토리얼을 위해 특별히 테스트 프로젝트를 생성하는 것이 좋습니다.
- 명령줄 Git에 대한 기본적인 이해입니다.

또한 GitLab Self-Managed에서는 시크릿 푸시 보호가 [인스턴스에서 활성화](secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance)되어 있는지 확인하세요.

## 시크릿 푸시 보호 활성화 {#enable-secret-push-protection}

시크릿 푸시 보호를 사용하려면 보호하려는 각 프로젝트에서 이를 활성화해야 합니다. 테스트 프로젝트에서 활성화해 보겠습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **시크릿 푸시 보호** 토글을 켭니다.

다음으로 시크릿 푸시 보호를 테스트합니다.

## 프로젝트에 시크릿을 푸시해 보기 {#try-pushing-a-secret-to-your-project}

GitLab은 특정 문자, 숫자 및 기호 패턴을 일치시켜 시크릿을 식별합니다. 이러한 패턴은 시크릿 유형을 식별하는 데도 사용됩니다. 가짜 시크릿 `glpat-12345678901234567890`을 프로젝트에 추가하여 이 기능을 테스트해 봅시다: <!-- gitleaks:allow -->

1. 프로젝트에서 새 브랜치를 체크아웃합니다:

   ```shell
   git checkout -b push-protection-tutorial
   ```

1. 다음 내용으로 새 파일을 생성합니다. `-` 전후의 공백을 제거하여 개인 액세스 토큰의 정확한 형식과 일치하는지 확인하세요:

   ```plaintext
   hello, world!

   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. 파일을 브랜치에 커밋합니다:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

   이제 시크릿이 커밋 히스토리에 입력되었습니다. 시크릿 푸시 보호는 시크릿을 커밋하는 것을 방지하지 않으며, 푸시할 때만 경고합니다.
1. GitLab에 변경 사항을 푸시합니다. 다음과 같은 결과가 표시됩니다:

   ```shell
   $ git push
   remote: GitLab:
   remote: PUSH BLOCKED: Secrets detected in code changes
   remote:
   remote: Secret push protection found the following secrets in commit: 123abc
   remote: -- myFile.txt:2 | GitLab Personal Access Token
   remote:
   remote: To push your changes you must remove the identified secrets.
   To gitlab.com:
    ! [remote rejected] push-protection-tutorial -> main (pre-receive hook declined)
   ```

   GitLab이 시크릿을 감지하고 푸시를 차단합니다. 오류 보고서에서 다음을 확인할 수 있습니다:

   - 시크릿이 포함된 커밋 (`123abc`)
   - 시크릿이 포함된 파일 및 줄 번호 (`myFile.txt:2`)
   - 시크릿의 유형 (`GitLab Personal Access Token`)

변경 사항을 성공적으로 푸시했다면 시크릿을 취소하고 교체하는 데 상당한 시간과 노력을 소요해야 합니다. 대신, [커밋 히스토리에서 시크릿을 제거](remove_secrets_tutorial.md)하여 시크릿 유출을 방지했다는 것을 알 수 있습니다.

## 시크릿 푸시 보호 건너뛰기 {#skip-secret-push-protection}

시크릿 푸시 보호가 시크릿을 식별했더라도 때로는 커밋을 푸시해야 합니다. 이는 GitLab이 거짓 양성을 감지할 때 발생할 수 있습니다. 설명을 위해 마지막 커밋을 GitLab에 푸시합니다.

### 푸시 옵션 사용 {#with-a-push-option}

푸시 옵션을 사용하여 시크릿 푸시 보호를 건너뛸 수 있습니다:

- 커밋을 `secret_push_protection.skip_all` 옵션으로 푸시합니다:

  ```shell
  git push -o secret_push_protection.skip_all
  ```

시크릿 푸시 보호가 건너뛰어지고 변경 사항이 원격으로 푸시됩니다.

### 커밋 메시지 사용 {#with-a-commit-message}

명령줄에 액세스할 수 없거나 푸시 옵션을 사용하고 싶지 않은 경우:

- 커밋 메시지에 `[skip secret push protection]` 문자열을 추가합니다. 예를 들어:

  ```shell
  git commit --amend -m "Add fake secret [skip secret push protection]"
  ```

여러 커밋이 있더라도 변경 사항을 푸시하기 위해 커밋 메시지 중 하나에 `[skip secret push protection]`을 추가하면 됩니다.

## 다음 단계 {#next-steps}

[파이프라인 시크릿 검색](pipeline/_index.md)을 활성화하여 프로젝트의 보안을 더욱 강화하는 것을 고려하세요.
