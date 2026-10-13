---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Free 푸시 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

Free 티어의 모든 프로젝트에 새 파일을 푸시할 때 파일당 100 MiB 제한이 적용됩니다.

100 MiB 이상의 새 파일을 Free 티어의 프로젝트에 푸시하면 오류가 표시됩니다. 예를 들어:

```shell
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 100.03 MiB | 1.08 MiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
remote: GitLab: You are attempting to check in one or more files which exceed the 100MiB limit:

- 257cc5642cb1a054f08cc83f2d943e56fd3ebe99 (123 MiB)
- 5716ca5987cbf97d6bb54920bea6adde242d87e6 (396 MiB)

Please refer to https://docs.gitlab.com/user/free_user_limit/ for further information.
To https://gitlab.com/group/my-project.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.com/group/my-project.git'
```

오류는 파일 이름 대신 파일의 고유 ID를 나열합니다. 고유 ID에서 파일 이름을 조회하려면 다음 명령을 실행합니다:

```shell
tree -r | grep <id>
```

Git은 대용량 비텍스트 기반 데이터를 잘 처리하도록 설계되지 않았으므로 이러한 파일에는 [Git LFS](../topics/git/lfs/_index.md)를 사용해야 합니다. Git LFS는 Git과 함께 작동하여 대용량 파일을 추적하도록 설계되었습니다.

## 문제 해결 {#troubleshooting}

푸시 제한을 해결하려고 할 때 다음 문제가 발생할 수 있습니다.

### 대용량 파일을 제거한 후 오류 메시지 표시 {#error-message-displays-after-removing-large-file}

리포지토리에서 대용량 파일을 삭제한 후에도 푸시 제한 오류가 발생할 수 있습니다. 이 문제를 해결하려면 대용량 파일을 도입한 커밋을 제거해 봅니다.

자세한 내용은 [커밋 되돌리기 및 히스토리 수정](../topics/git/undo.md#revert-commits-and-modify-history)을 참조하세요.
