---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 백업 문제 해결
---

GitLab을 백업할 때 다음과 같은 이슈가 발생할 수 있습니다.

## 비밀번호 파일이 손실된 경우 {#when-the-secrets-file-is-lost}

[비밀번호 파일을 백업](backup_gitlab.md#storing-configuration-files)하지 않았다면, GitLab을 정상적으로 작동하게 하려면 여러 단계를 완료해야 합니다.

비밀번호 파일은 필수 및 민감한 정보가 포함된 열의 암호화 키를 저장하는 역할을 합니다. 키가 손실되면 GitLab은 해당 열을 복호화할 수 없으므로 다음 항목에 대한 액세스가 차단됩니다:

- [CI/CD 변수](../../ci/variables/_index.md)
- [Kubernetes / GCP 통합](../../user/infrastructure/clusters/_index.md)
- [사용자 지정 Pages 도메인](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [프로젝트 오류 추적](../../operations/error_tracking.md)
- [러너 인증](../../ci/runners/_index.md)
- [프로젝트 미러링](../../user/project/repository/mirror/_index.md)
- [통합](../../user/project/integrations/_index.md)
- [웹후크](../../user/project/integrations/webhooks.md)
- [배포 토큰](../../user/project/deploy_tokens/_index.md)

CI/CD 변수와 러너 인증의 경우, 다음과 같은 예상치 못한 동작이 발생할 수 있습니다:

- 작업이 고착됨.
- 500 오류.

이 경우 CI/CD 변수와 러너 인증을 위한 모든 토큰을 재설정해야 하며, 이는 다음 섹션에서 자세히 설명합니다. 토큰을 재설정한 후에는 프로젝트를 방문할 수 있고 작업이 다시 실행되기 시작합니다.

> [!warning]
> 이 섹션의 단계는 이전에 나열된 항목에 대한 데이터 손실을 초래할 수 있습니다. Premium 또는 Ultimate 고객인 경우 [지원 요청](https://support.gitlab.com/hc/en-us/requests/new)을 열어 주시기 바랍니다.

### 모든 값을 복호화할 수 있는지 확인 {#verify-that-all-values-can-be-decrypted}

[Rake 작업](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)을 사용하여 데이터베이스에 복호화할 수 없는 값이 포함되어 있는지 확인할 수 있습니다.

### 백업 수행 {#take-a-backup}

손실된 비밀번호 파일을 해결하기 위해 GitLab 데이터를 직접 수정해야 합니다.

> [!warning]
> 변경을 시도하기 전에 전체 데이터베이스 백업을 생성해야 합니다.

### 사용자 2단계 인증(2FA) 비활성화 {#disable-user-two-factor-authentication-2fa}

2FA가 활성화된 사용자는 GitLab에 로그인할 수 없습니다. 이 경우 [모든 사용자에 대해 2FA 비활성화](../../security/two_factor_authentication.md#for-all-users)를 수행해야 하며, 그 후 사용자는 2FA를 다시 활성화해야 합니다.

### CI/CD 변수 재설정 {#reset-cicd-variables}

1. 데이터베이스 콘솔에 들어갑니다:

   Linux 패키지(Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. `ci_group_variables` 및 `ci_variables` 테이블을 검토합니다:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   이것들이 삭제해야 할 변수입니다.

1. 모든 변수 삭제:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. 변수를 삭제할 특정 그룹 또는 프로젝트를 알고 있다면, `WHERE` 문을 포함하여 `DELETE`에서 이를 지정할 수 있습니다:

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

변경 사항을 적용하려면 GitLab을 재구성하거나 다시 시작해야 할 수 있습니다.

### 러너 등록 토큰 재설정 {#reset-runner-registration-tokens}

1. 데이터베이스 콘솔에 들어갑니다:

   Linux 패키지(Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. 프로젝트, 그룹 및 전체 인스턴스에 대한 모든 토큰을 지웁니다:

   > [!warning]
   > 최종 `UPDATE` 작업은 러너가 새 작업을 선택하지 못하도록 합니다. 새 러너를 등록해야 합니다.

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear key used for JWT authentication
   -- This may break the $CI_JWT_TOKEN job variable:
   -- https://gitlab.com/gitlab-org/gitlab/-/issues/325965
   UPDATE application_settings SET encrypted_ci_jwt_signing_key = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

### 보류 중인 파이프라인 작업 재설정 {#reset-pending-pipeline-jobs}

1. 데이터베이스 콘솔에 들어갑니다:

   Linux 패키지(Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. 보류 중인 작업의 모든 토큰을 지웁니다:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token_encrypted = null;
   ```

나머지 기능에 대해서도 유사한 전략을 사용할 수 있습니다. 복호화할 수 없는 데이터를 제거하면 GitLab을 작동 상태로 복원할 수 있으며, 손실된 데이터는 수동으로 교체할 수 있습니다.

### 통합 및 웹후크 수정 {#fix-integrations-and-webhooks}

비밀번호를 손실한 경우, [통합 설정](../../user/project/integrations/_index.md) 및 [웹후크 설정](../../user/project/integrations/webhooks.md) 페이지에 `500` 오류 메시지가 표시될 수 있습니다. 손실된 비밀번호는 이전에 구성된 통합 또는 웹후크가 있는 프로젝트의 리포지토리에 액세스하려고 할 때 `500` 오류를 발생시킬 수 있습니다.

해결책은 영향을 받는 테이블(암호화된 열을 포함하는 테이블)을 자르는 것입니다. 이렇게 하면 구성된 모든 통합, 웹후크 및 관련 메타데이터가 삭제됩니다. 데이터를 삭제하기 전에 비밀번호가 근본 원인인지 확인해야 합니다.

1. 데이터베이스 콘솔에 들어갑니다:

   Linux 패키지(Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. 다음 테이블을 자릅니다:

   ```sql
   -- truncate web_hooks table
   TRUNCATE integrations, chat_names, issue_tracker_data, jira_tracker_data, slack_integrations, web_hooks, zentao_tracker_data, web_hook_logs CASCADE;
   ```

## 컨테이너 레지스트리가 복원되지 않음 {#container-registry-is-not-restored}

[컨테이너 레지스트리](../../user/packages/container_registry/_index.md)를 사용하는 환경에서 백업을 복원할 때 컨테이너 레지스트리가 활성화되지 않은 새로 설치된 환경으로 복원하면 컨테이너 레지스트리가 복원되지 않습니다.

컨테이너 레지스트리도 복원하려면 백업을 복원하기 전에 새 환경에서 [활성화](../packages/container_registry.md#enable-the-container-registry)해야 합니다.

## 백업에서 복원한 후 컨테이너 레지스트리 푸시 실패 {#container-registry-push-failures-after-restoring-from-a-backup}

[컨테이너 레지스트리](../../user/packages/container_registry/_index.md)를 사용하는 경우, 레지스트리 데이터를 복원한 후 Linux 패키지(Omnibus) 인스턴스에서 백업을 복원한 후 레지스트리로의 푸시가 실패할 수 있습니다.

이러한 실패는 레지스트리 로그에서 권한 이슈를 언급하며, 다음과 유사합니다:

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

이 이슈는 `git` 권한 없는 사용자로 복원이 실행되어 복원 프로세스 중에 레지스트리 파일에 올바른 소유권을 할당할 수 없기 때문에 발생합니다([이슈 #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "레지스트리 파일 시스템의 잘못된 권한 복원 후")).

레지스트리를 다시 작동시키려면:

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

레지스트리의 기본 파일 시스템 위치를 변경한 경우, `/var/opt/gitlab/gitlab-rails/shared/registry/docker` 대신 사용자 지정 위치에 대해 `chown`을 실행합니다.

## 백업이 Gzip 오류로 완료되지 못함 {#backup-fails-to-complete-with-gzip-error}

백업을 실행할 때 Gzip 오류 메시지가 나타날 수 있습니다:

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

이 경우 다음을 확인합니다:

- Gzip 작업을 위한 디스크 공간이 충분한지 확인합니다. [기본 전략](backup_gitlab.md#backup-strategy-option)을 사용하는 백업의 경우 백업 생성 중에 인스턴스 크기의 절반에 해당하는 여유 디스크 공간이 필요한 것이 일반적입니다.
- NFS를 사용 중인 경우, 마운트 옵션 `timeout`이 설정되었는지 확인합니다. 기본값은 `600`이며, 이를 더 작은 값으로 변경하면 이 오류가 발생합니다.

## 백업이 `File name too long` 오류로 실패 {#backup-fails-with-file-name-too-long-error}

백업 중에 `File name too long` 오류([이슈 #354984](https://gitlab.com/gitlab-org/gitlab/-/issues/354984))가 발생할 수 있습니다. 예를 들어:

```plaintext
Problem: <class 'OSError: [Errno 36] File name too long:
```

이 문제는 백업 스크립트가 완료되지 못하도록 합니다. 이 문제를 해결하려면 문제를 일으키는 파일명을 자르거나 줄여야 합니다. 파일 확장자를 포함하여 최대 246자가 허용됩니다.

> [!warning]
> 이 섹션의 단계는 데이터 손실을 초래할 수 있습니다. 모든 단계를 주어진 순서대로 엄격하게 따라야 합니다. Premium 또는 Ultimate 고객인 경우 [지원 요청](https://support.gitlab.com/hc/en-us/requests/new)을 열어 주시기 바랍니다.

파일명을 자르거나 줄여서 오류를 해결하려면 다음을 수행합니다:

- 데이터베이스에서 추적하지 않는 원격 업로드 파일을 정리합니다.
- 데이터베이스의 파일명을 자르거나 줄입니다.
- 백업 작업을 다시 실행합니다.

### 원격 업로드 파일 정리 {#clean-up-remote-uploaded-files}

[알려진 이슈](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45425)로 인해 부모 리소스가 삭제된 후에도 개체 저장소 업로드가 남아 있었습니다. 이 이슈는 [해결](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18698)되었습니다.

이 파일을 수정하려면 저장소에는 있지만 `uploads` 데이터베이스 테이블에서 추적하지 않는 모든 원격 업로드 파일을 정리해야 합니다.

1. GitLab 데이터베이스에 없는 경우 손실 및 발견 디렉터리로 이동할 수 있는 모든 개체 저장소 업로드 파일을 나열합니다:

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
   ```

1. 이 파일을 삭제하고 참조되지 않은 모든 업로드 파일을 제거할 확신이 있으면 다음을 실행합니다:

   > [!warning]
   > 다음 작업은 되돌릴 수 없습니다.

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production DRY_RUN=false
   ```

### 데이터베이스에서 참조하는 파일명 자르기 {#truncate-the-filenames-referenced-by-the-database}

문제를 일으키는 데이터베이스에서 참조하는 파일을 자르거나 줄여야 합니다. 데이터베이스에서 참조하는 파일명은 다음과 같이 저장됩니다:

- `uploads` 테이블에.
- 찾은 참조. 다른 데이터베이스 테이블 및 열에서 찾은 모든 참조입니다.
- 파일 시스템에서.

`uploads` 테이블의 파일명을 자르거나 줄입니다:

1. 데이터베이스 콘솔에 들어갑니다:

   Linux 패키지(Omnibus):

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   자체 컴파일된 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. `uploads` 테이블에서 246자보다 긴 파일명을 검색합니다:

   다음 쿼리는 0~10000 배치의 246자보다 긴 파일명이 있는 `uploads` 레코드를 선택합니다. 이렇게 하면 수천 개의 레코드가 있는 테이블이 있는 대규모 GitLab 인스턴스의 성능이 향상됩니다.

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, id, path
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   SELECT
      u.id,
      u.path,
      -- Current filename
      (regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] AS current_filename,
      -- New filename
      CONCAT(
         LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
         COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
      ) AS new_filename,
      -- New path
      CONCAT(
         COALESCE((regexp_match(u.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      ) AS new_path
   FROM uploads_with_long_filenames AS u
   WHERE u.row_id > 0 AND u.row_id <= 10000;
   ```

   출력 예:

   ```postgresql
   -[ RECORD 1 ]----+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   id               | 34
   path             | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   current_filename | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   new_filename     | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   new_path         | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   ```

   위치:

   - `current_filename`: 246자보다 긴 파일명입니다.
   - `new_filename`: 최대 246자로 자르거나 줄인 파일명입니다.
   - `new_path`: `new_filename`(자르거나 줄인)을 고려한 새 경로입니다.

   배치 결과를 검증한 후, 배치 크기(`row_id`)를 다음 숫자 시퀀스(10000~20000)를 사용하여 변경해야 합니다. `uploads` 테이블의 마지막 레코드에 도달할 때까지 이 프로세스를 반복합니다.

1. `uploads` 테이블에서 찾은 파일을 긴 파일명에서 새로 자르거나 줄인 파일명으로 이름을 바꿉니다. 다음 쿼리는 업데이트를 롤백하므로 트랜잭션 래퍼에서 결과를 안전하게 확인할 수 있습니다:

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   BEGIN;
   WITH updated_uploads AS (
      UPDATE uploads
      SET
         path =
         CONCAT(
            COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
            CONCAT(
               LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
               COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
            )
         )
      FROM
         uploads_with_long_filenames AS updatable_uploads
      WHERE
         uploads.id = updatable_uploads.id
      AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000
      RETURNING uploads.*
   )
   SELECT id, path FROM updated_uploads;
   ROLLBACK;
   ```

   배치 업데이트 결과를 검증한 후, 배치 크기(`row_id`)를 다음 숫자 시퀀스(10000~20000)를 사용하여 변경해야 합니다. `uploads` 테이블의 마지막 레코드에 도달할 때까지 이 프로세스를 반복합니다.

1. 이전 쿼리의 새 파일명이 예상된 파일명인지 확인합니다. 이전 단계에서 찾은 레코드를 246자로 자르거나 줄이려면 다음을 실행합니다:

   > [!warning]
   > 다음 작업은 되돌릴 수 없습니다.

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   UPDATE uploads
   SET
   path =
      CONCAT(
         COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      )
   FROM
   uploads_with_long_filenames AS updatable_uploads
   WHERE
   uploads.id = updatable_uploads.id
   AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000;
   ```

   배치 업데이트를 완료한 후, 배치 크기(`updatable_uploads.row_id`)를 다음 숫자 시퀀스(10000~20000)를 사용하여 변경해야 합니다. `uploads` 테이블의 마지막 레코드에 도달할 때까지 이 프로세스를 반복합니다.

찾은 참조의 파일명을 자르거나 줄입니다:

1. 이러한 레코드가 어디서 참조되는지 확인합니다. 이를 수행하는 한 가지 방법은 데이터베이스를 덤프하고 부모 디렉터리 이름 및 파일명을 검색하는 것입니다:

   1. 데이터베이스를 덤프하려면 다음 명령을 예로 들어 사용할 수 있습니다:

      ```shell
      pg_dump -h /var/opt/gitlab/postgresql/ -d gitlabhq_production > gitlab-dump.tmp
      ```

   1. 그런 다음 `grep` 명령을 사용하여 참조를 검색할 수 있습니다. 부모 디렉터리와 파일명을 결합하면 좋은 아이디어가 될 수 있습니다. 예를 들어:

      ```shell
      grep public/alongfilenamehere.txt gitlab-dump.tmp
      ```

1. `uploads` 테이블을 쿼리하여 얻은 새 파일명을 사용하여 긴 파일명을 바꿉니다.

파일 시스템의 파일명을 자르거나 줄입니다. 파일 시스템의 파일을 `uploads` 테이블을 쿼리하여 얻은 새 파일명으로 수동으로 이름을 바꿔야 합니다.

### 백업 작업 다시 실행 {#re-run-the-backup-task}

이전 단계를 모두 완료한 후 백업 작업을 다시 실행합니다.

## 데이터베이스 백업 복원이 `pg_stat_statements`이 이전에 활성화되었을 때 실패 {#restoring-database-backup-fails-when-pg_stat_statements-was-previously-enabled}

GitLab PostgreSQL 데이터베이스 백업에는 이전에 데이터베이스에서 활성화된 확장을 활성화하는 데 필요한 모든 SQL 문이 포함됩니다.

`pg_stat_statements` 확장은 `superuser` 역할이 있는 PostgreSQL 사용자에 의해서만 활성화하거나 비활성화할 수 있습니다. 복원 프로세스는 제한된 권한이 있는 데이터베이스 사용자를 사용하므로 다음 SQL 문을 실행할 수 없습니다:

```sql
DROP EXTENSION IF EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
```

`pg_stats_statements` 확장이 없는 PostgreSQL 인스턴스에서 백업을 복원하려고 하면 다음 오류 메시지가 표시됩니다:

```plaintext
ERROR: permission denied to create extension "pg_stat_statements"
HINT: Must be superuser to create this extension.
ERROR: extension "pg_stat_statements" does not exist
```

`pg_stats_statements` 확장이 활성화된 인스턴스에서 복원하려고 하면 정리 단계가 다음과 유사한 오류 메시지로 실패합니다:

```plaintext
rake aborted!
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Caused by:
PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:db:drop_tables
(See full trace by running task with --trace)
```

### `pg_stat_statements`을 포함하도록 덤프 파일 방지 {#prevent-the-dump-file-to-include-pg_stat_statements}

백업 번들의 일부인 PostgreSQL 덤프 파일에 확장이 포함되는 것을 방지하려면 `public` 스키마 이외의 스키마에서 확장을 활성화합니다:

```sql
CREATE SCHEMA adm;
CREATE EXTENSION pg_stat_statements SCHEMA adm;
```

확장이 이전에 `public` 스키마에서 활성화된 경우 새 스키마로 이동합니다:

```sql
CREATE SCHEMA adm;
ALTER EXTENSION pg_stat_statements SET SCHEMA adm;
```

스키마를 변경한 후 `pg_stat_statements` 데이터를 쿼리하려면 새 스키마를 사용하여 보기 이름 앞에 접두사를 붙입니다:

```sql
SELECT * FROM adm.pg_stat_statements limit 0;
```

타사 모니터링 솔루션이 `public` 스키마에서 활성화되기를 원하므로 호환되도록 하려면 `search_path`에 포함해야 합니다:

```sql
set search_path to public,adm;
```

### `pg_stat_statements`에 대한 참조를 제거하도록 기존 덤프 파일 수정 {#fix-an-existing-dump-file-to-remove-references-to-pg_stat_statements}

기존 백업 파일을 수정하려면 다음 변경을 수행합니다:

1. 백업에서 다음 파일을 추출합니다: `db/database.sql.gz`.
1. 파일을 압축 해제하거나 압축 상태에서 파일을 처리할 수 있는 편집기를 사용합니다.
1. 다음 줄 또는 유사한 줄을 제거합니다:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
   ```

   ```sql
   COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';
   ```

1. 변경 사항을 저장하고 파일을 다시 압축합니다.
1. 수정된 `db/database.sql.gz`로 백업 파일을 업데이트합니다.
