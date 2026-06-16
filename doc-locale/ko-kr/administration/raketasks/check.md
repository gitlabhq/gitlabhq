---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 무결성 검사 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 다양한 구성 요소의 무결성을 검사하는 Rake 작업을 제공합니다. [GitLab 구성 검사 Rake 작업](maintenance.md#check-gitlab-configuration)을 참고하세요.

## 리포지토리 무결성 {#repository-integrity}

Git이 매우 복원력이 있고 데이터 무결성 문제를 방지하려고 시도하지만 상황이 잘못될 때가 있습니다. 다음 Rake 작업은 GitLab 관리자가 문제 리포지토리를 진단하여 수정할 수 있도록 도움이 됩니다.

이러한 Rake 작업은 Git 리포지토리의 무결성을 결정하기 위해 세 가지 다른 방법을 사용합니다.

1. Git 리포지토리 파일 시스템 검사 ([`git fsck`](https://git-scm.com/docs/git-fsck)). 이 단계는 리포지토리의 개체 연결성과 유효성을 확인합니다.
1. 리포지토리 디렉터리에서 `config.lock`을 확인하세요.
1. `refs/heads`에 있는 브랜치/참조 잠금 파일을 확인하세요.

`config.lock` 또는 참조 잠금의 존재만으로는 반드시 문제를 나타내지는 않습니다. Git과 GitLab이 리포지토리에서 작업을 수행할 때 잠금 파일이 정기적으로 생성되고 제거됩니다. 데이터 무결성 문제를 방지하기 위해 존재합니다. 그러나 Git 작업이 중단되면 이러한 잠금이 제대로 정리되지 않을 수 있습니다.

다음 증상은 리포지토리 무결성 문제를 나타낼 수 있습니다. 사용자가 이러한 증상을 경험하면 아래에 설명된 Rake 작업을 사용하여 정확히 어떤 리포지토리가 문제를 일으키고 있는지 확인할 수 있습니다.

- 코드를 푸시하려고 할 때 오류 수신 - `remote: error: cannot lock ref`
- GitLab 대시보드를 보거나 특정 프로젝트에 액세스할 때 500 오류.

### 모든 프로젝트 코드 리포지토리 확인 {#check-all-project-code-repositories}

이 작업은 프로젝트 코드 리포지토리를 반복하고 이전에 설명한 무결성 검사를 실행합니다. 프로젝트가 풀 리포지토리를 사용하는 경우 해당 리포지토리도 검사됩니다. 다른 유형의 Git 리포지토리는 [검사되지 않습니다](https://gitlab.com/gitlab-org/gitaly/-/issues/3643).

프로젝트 코드 리포지토리를 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### 특정 프로젝트 코드 리포지토리 확인 {#check-specific-project-code-repositories}

{{< history >}}

- [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197990).

{{< /history >}}

`PROJECT_IDS` 환경 변수를 쉼표로 구분된 프로젝트 ID 목록으로 설정하여 특정 프로젝트 ID가 있는 프로젝트의 리포지토리 검사를 제한합니다.

예를 들어 프로젝트 ID `1`과 `3`가 있는 프로젝트의 리포지토리를 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo PROJECT_IDS="1,3" gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo -u git -H PROJECT_IDS="1,3" bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 리포지토리 참조의 체크섬 {#checksum-of-repository-refs}

하나의 Git 리포지토리를 각 리포지토리의 모든 참조를 체크섬하여 다른 리포지토리와 비교할 수 있습니다. 두 리포지토리가 동일한 참조를 가지고 있고 두 리포지토리 모두 무결성 검사를 통과하면 두 리포지토리가 동일하다고 확신할 수 있습니다.

예를 들어 이는 리포지토리의 백업과 소스 리포지토리를 비교하는 데 사용할 수 있습니다.

### 모든 GitLab 리포지토리 확인 {#check-all-gitlab-repositories}

이 작업은 GitLab 서버의 모든 리포지토리를 반복하고 `<PROJECT ID>,<CHECKSUM>` 형식으로 체크섬을 출력합니다.

- 리포지토리가 없으면 프로젝트 ID는 빈 체크섬입니다.
- 리포지토리는 존재하지만 비어 있으면 출력 체크섬은 `0000000000000000000000000000000000000000`입니다.
- 존재하지 않는 프로젝트는 건너뜁니다.

모든 GitLab 리포지토리를 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:git:checksum_projects
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:checksum_projects RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

예를 들어:

- ID#2인 프로젝트가 존재하지 않으면 건너뜁니다.
- ID#4인 프로젝트에는 리포지토리가 없으므로 체크섬이 비어 있습니다.
- ID#5인 프로젝트에는 빈 리포지토리가 있으므로 체크섬은 `0000000000000000000000000000000000000000`입니다.

출력은 다음과 같이 표시됩니다:

```plaintext
1,cfa3f06ba235c13df0bb28e079bcea62c5848af2
3,3f3fb58a8106230e3a6c6b48adc2712fb3b6ef87
4,
5,0000000000000000000000000000000000000000
6,6c6b48adc2712fb3b6ef87cfa3f06ba235c13df0
```

### 특정 GitLab 리포지토리 확인 {#check-specific-gitlab-repositories}

선택적으로 환경 변수 `CHECKSUM_PROJECT_IDS`을 쉼표로 구분된 정수 목록으로 설정하여 특정 프로젝트 ID를 체크섬할 수 있습니다. 예를 들어:

```shell
sudo CHECKSUM_PROJECT_IDS="1,3" gitlab-rake gitlab:git:checksum_projects
```

## 업로드된 파일 무결성 {#uploaded-files-integrity}

다양한 유형의 파일을 GitLab 설치에 사용자가 업로드할 수 있습니다. 이러한 무결성 검사는 누락된 파일을 감지할 수 있습니다. 또한 로컬로 저장된 파일의 경우 체크섬이 생성되어 업로드 시 데이터베이스에 저장되며 이러한 검사는 현재 파일에 대해 확인합니다.

다음 파일 유형에 대해 무결성 검사가 지원됩니다:

- CI 아티팩트
- LFS 개체
- 프로젝트 수준 보안 파일(GitLab 16.1.0에서 도입됨)
- 사용자 업로드

업로드된 파일의 무결성을 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:artifacts:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:ci_secure_files:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:lfs:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:uploads:check RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

이러한 작업은 특정 값을 재정의하는 데 사용할 수 있는 일부 환경 변수도 허용합니다:

| 변수  | 유형    | 설명 |
|-----------|---------|-------------|
| `BATCH`   | 정수 | 배치 크기를 지정합니다. 기본값은 200입니다. |
| `ID_FROM` | 정수 | 시작할 ID를 지정합니다(해당 값 포함). |
| `ID_TO`   | 정수 | 종료할 ID 값을 지정합니다(해당 값 포함). |
| `VERBOSE` | 부울 | 실패가 요약되지 않고 개별적으로 나열되도록 합니다. |

```shell
sudo gitlab-rake gitlab:artifacts:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:ci_secure_files:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:lfs:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:uploads:check BATCH=100 ID_FROM=50 ID_TO=250
```

출력 예:

```shell
$ sudo gitlab-rake gitlab:uploads:check
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
- 4357..5762: Failures: 1
- 5764..7140: Failures: 2
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

상세 출력 예:

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
  - Upload: 3573: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/7a77cc52947bfe188adeff42f890bb77/image.png>
  - Upload: 3580: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/2840ba1ba3b2ecfa3478a7b161375f8a/pug.png>
- 4357..5762: Failures: 1
  - Upload: 4636: #<Google::Apis::ServerError: Server error>
- 5764..7140: Failures: 2
  - Upload: 5812: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
  - Upload: 5837: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

## LDAP 검사 {#ldap-check}

LDAP 검사 Rake 작업은 바인드 DN 및 암호 자격 증명(구성된 경우)을 테스트하고 LDAP 사용자 샘플을 나열합니다. 이 작업은 `gitlab:check` 작업의 일부로도 실행되지만 독립적으로 실행할 수 있습니다. 자세한 내용은 [LDAP Rake 작업 - LDAP 검사](ldap.md#check)를 참고하세요.

## 현재 보안 암호를 사용하여 데이터베이스 값을 복호화할 수 있는지 확인 {#verify-database-values-can-be-decrypted-using-the-current-secrets}

이 작업은 데이터베이스의 모든 가능한 암호화된 값을 실행하여 현재 보안 파일 `gitlab-secrets.json`을 사용하여 복호화할 수 있는지 확인합니다.

자동 해결은 아직 구현되지 않았습니다. 복호화할 수 없는 값이 있는 경우 단계에 따라 재설정할 수 있습니다. 자세한 내용은 [보안 파일이 손실되었을 때](../backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)에 대한 설명서를 참고하세요.

데이터베이스 크기에 따라 매우 오래 걸릴 수 있으며 모든 테이블의 모든 행을 검사합니다.

현재 보안 암호를 사용하여 데이터베이스 값을 복호화할 수 있는지 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

**Example output**

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
I, [2020-06-11T17:18:14.938335 #27148]  INFO -- : - Group failures: 1
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

### 상세 모드 {#verbose-mode}

복호화할 수 없는 행과 열에 대한 더 자세한 정보를 얻으려면 `VERBOSE` 환경 변수를 전달할 수 있습니다.

현재 보안 암호를 사용하여 데이터베이스 값을 자세한 정보로 복호화할 수 있는지 확인하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets VERBOSE=1
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production VERBOSE=1
```

{{< /tab >}}

{{< /tabs >}}

**Example verbose output**

<!-- vale gitlab_base.SentenceSpacing = NO -->

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
D, [2020-06-11T17:19:53.224344 #27351] DEBUG -- : > Something went wrong for Group[10].runners_token: Validation failed: Route can't be blank
I, [2020-06-11T17:19:53.225178 #27351]  INFO -- : - Group failures: 1
D, [2020-06-11T17:19:53.225267 #27351] DEBUG -- :   - Group[10]: runners_token
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

<!-- vale gitlab_base.SentenceSpacing = YES -->

## 복구할 수 없는 경우 암호화된 토큰 재설정 {#reset-encrypted-tokens-when-they-cant-be-recovered}

{{< history >}}

- [GitLab 16.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131893).

{{< /history >}}

> [!warning]
> 이 작업은 위험하며 데이터 손실이 발생할 수 있습니다. 극도의 주의를 기울여 진행하세요. 이 작업을 수행하기 전에 GitLab 내부에 대한 지식이 있어야 합니다.

경우에 따라 암호화된 토큰을 더 이상 복구할 수 없고 문제가 발생합니다. 대부분의 경우 그룹 및 프로젝트의 러너 등록 토큰이 매우 큰 인스턴스에서 손상될 수 있습니다.

손상된 토큰을 재설정하려면:

1. 손상된 암호화된 토큰이 있는 데이터베이스 모델을 식별합니다. 예를 들어 `Group` 및 `Project`일 수 있습니다.
1. 손상된 토큰을 식별합니다. 예를 들어 `runners_token`.
1. 손상된 토큰을 재설정하려면 `gitlab:doctor:reset_encrypted_tokens`을 `VERBOSE=true MODEL_NAMES=Model1,Model2 TOKEN_NAMES=broken_token1,broken_token2`로 실행합니다. 예를 들어:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="직접 컴파일된 설치(소스)" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

   이 작업이 수행하려고 하는 모든 작업을 볼 수 있습니다:

   ```plain
   I, [2023-09-26T16:20:23.230942 #88920]  INFO -- : Resetting runners_token on Project, Group if they can not be read
   I, [2023-09-26T16:20:23.230975 #88920]  INFO -- : Executing in DRY RUN mode, no records will actually be updated
   D, [2023-09-26T16:20:30.151585 #88920] DEBUG -- : > Fix Project[1].runners_token
   I, [2023-09-26T16:20:30.151617 #88920]  INFO -- : Checked 1/9 Projects
   D, [2023-09-26T16:20:30.151873 #88920] DEBUG -- : > Fix Project[3].runners_token
   D, [2023-09-26T16:20:30.152975 #88920] DEBUG -- : > Fix Project[10].runners_token
   I, [2023-09-26T16:20:30.152992 #88920]  INFO -- : Checked 11/29 Projects
   I, [2023-09-26T16:20:30.153230 #88920]  INFO -- : Checked 21/29 Projects
   I, [2023-09-26T16:20:30.153882 #88920]  INFO -- : Checked 29 Projects
   D, [2023-09-26T16:20:30.195929 #88920] DEBUG -- : > Fix Group[22].runners_token
   I, [2023-09-26T16:20:30.196125 #88920]  INFO -- : Checked 1/19 Groups
   D, [2023-09-26T16:20:30.196192 #88920] DEBUG -- : > Fix Group[25].runners_token
   D, [2023-09-26T16:20:30.197557 #88920] DEBUG -- : > Fix Group[82].runners_token
   I, [2023-09-26T16:20:30.197581 #88920]  INFO -- : Checked 11/19 Groups
   I, [2023-09-26T16:20:30.198455 #88920]  INFO -- : Checked 19 Groups
   I, [2023-09-26T16:20:30.198462 #88920]  INFO -- : Done!
   ```

1. 이 작업이 올바른 토큰을 재설정한다고 확신하면 드라이 런 모드를 비활성화하고 작업을 다시 실행합니다:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="직접 컴파일된 설치(소스)" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

`gitlab:doctor:reset_encrypted_tokens` 작업에는 다음과 같은 제한이 있습니다:

- 예를 들어 `ApplicationSetting:ci_jwt_signing_key`같은 토큰이 아닌 속성은 재설정되지 않습니다.
- 단일 모델 레코드에서 복호화할 수 없는 속성이 2개 이상 있으면 작업이 `TypeError: no implicit conversion of nil into String ... block in aes256_gcm_decrypt` 오류로 실패합니다.

## 문제 해결 {#troubleshooting}

다음은 이전에 문서화된 Rake 작업을 사용하여 발견할 수 있는 문제에 대한 해결책입니다.

### 분리된 개체 {#dangling-objects}

`gitlab-rake gitlab:git:fsck` 작업은 다음과 같은 분리된 개체를 찾을 수 있습니다:

```plaintext
dangling blob a12...
dangling commit b34...
dangling tag c56...
dangling tree d78...
```

이를 삭제하려면 [하우스키핑 실행](../housekeeping.md)을 시도하세요.

문제가 지속되면 [Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 통해 가비지 수집을 트리거하려고 시도하세요:

```ruby
p = Project.find_by_path("project-name")
Repositories::HousekeepingService.new(p, :gc).execute
```

분리된 개체가 기본 2주 유예 기간보다 최신이고 자동으로 만료될 때까지 기다리지 않으려면 다음을 실행하세요:

```ruby
Repositories::HousekeepingService.new(p, :prune).execute
```

### 누락된 원격 업로드에 대한 참조 삭제 {#delete-references-to-missing-remote-uploads}

`gitlab-rake gitlab:uploads:check VERBOSE=1`은 외부에서 삭제되었지만 GitLab 데이터베이스에 여전히 참조가 있는 원격 개체를 감지합니다.

오류 메시지가 있는 출력 예:

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 100..434: Failures: 2
- Upload: 100: Remote object does not exist
- Upload: 101: Remote object does not exist
Done!
```

외부에서 삭제된 원격 업로드에 대한 이러한 참조를 삭제하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 열고 다음을 실행하세요:

```ruby
uploads_deleted=0
Upload.find_each do |upload|
  next if upload.retrieve_uploader.file.exists?
  uploads_deleted=uploads_deleted + 1
  p upload                            ### allow verification before destroy
  # p upload.destroy!                 ### uncomment to actually destroy
end
p "#{uploads_deleted} remote objects were destroyed."
```

### 누락된 아티팩트에 대한 참조 삭제 {#delete-references-to-missing-artifacts}

`gitlab-rake gitlab:artifacts:check VERBOSE=1`은 아티팩트(또는 `job.log` 파일)를 감지할 때:

- GitLab 외부에서 삭제됨.
- GitLab 데이터베이스에 여전히 참조가 있습니다.

이 시나리오가 감지되면 Rake 작업에 오류 메시지가 표시됩니다. 예를 들어:

```shell
Checking integrity of Job artifacts
- 1..15: Failures: 2
  - Job artifact: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/artifacts/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/job.log>
  - Job artifact: 15: Remote object does not exist
Done!

```

누락된 로컬 및/또는 원격 아티팩트(`job.log` 파일)에 대한 이러한 참조를 삭제하려면:

1. [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 열세요.
1. 다음 Ruby 코드를 실행하세요:

   ```ruby
   artifacts_deleted = 0
   ::Ci::JobArtifact.find_each do |artifact|                      ### Iterate artifacts
   #  next if artifact.file.filename != "job.log"                 ### Uncomment if only `job.log` files' references are to be processed
     next if artifact.file.file.exists?                           ### Skip if the file reference is valid
     artifacts_deleted += 1
     puts "#{artifact.id}  #{artifact.file.path} is missing."     ### Allow verification before destroy
   #  artifact.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{artifacts_deleted}"
   ```

### 누락된 LFS 개체에 대한 참조 삭제 {#delete-references-to-missing-lfs-objects}

`gitlab-rake gitlab:lfs:check VERBOSE=1`이 데이터베이스에는 있지만 디스크에는 없는 LFS 개체를 감지하면 [LFS 설명서의 절차를 따르세요](../lfs/_index.md#missing-lfs-objects)하여 데이터베이스 항목을 제거합니다.

### 분리된 개체 저장소 참조 업데이트 {#update-dangling-object-storage-references}

[개체 저장소에서 로컬 저장소로 마이그레이션](../cicd/job_artifacts.md#migrating-from-object-storage-to-local-storage)했는데 파일이 누락되었으면 분리된 데이터베이스 참조가 남아 있습니다.

이는 마이그레이션 로그에서 다음과 같은 오류로 표시됩니다:

```shell
W, [2022-11-28T13:14:09.283833 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 11 with error: undefined method `body' for nil:NilClass
W, [2022-11-28T13:14:09.296911 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 12 with error: undefined method `body' for nil:NilClass
```

개체 저장소를 비활성화한 후 [누락된 아티팩트에 대한 참조 삭제](check.md#delete-references-to-missing-artifacts)를 시도하면 다음 오류가 발생합니다:

```plaintext
RuntimeError (Object Storage is not enabled for JobArtifactUploader)
```

이러한 참조를 로컬 저장소를 가리키도록 업데이트하려면:

1. [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 열세요.
1. 다음 Ruby 코드를 실행하세요:

   ```ruby
   artifacts_updated = 0
   ::Ci::JobArtifact.find_each do |artifact|                    ### Iterate artifacts
     next if artifact.file_store != 2                           ### Skip if file_store already points to local storage
     artifacts_updated += 1
     # artifact.update(file_store: 1)                           ### Uncomment to actually update
   end
   puts "Updated file_store count: #{artifacts_updated}"
   ```

[누락된 아티팩트에 대한 참조 삭제](check.md#delete-references-to-missing-artifacts) 스크립트는 이제 올바르게 작동하고 데이터베이스를 정리합니다.

### 누락된 보안 파일에 대한 참조 삭제 {#delete-references-to-missing-secure-files}

`VERBOSE=1 gitlab-rake gitlab:ci_secure_files:check`은 보안 파일을 감지할 때:

- GitLab 외부에서 삭제됨.
- GitLab 데이터베이스에 여전히 참조가 있습니다.

이 시나리오가 감지되면 Rake 작업에 오류 메시지가 표시됩니다. 예를 들어:

```shell
Checking integrity of CI Secure Files
- 1..15: Failures: 2
  - Job SecureFile: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/ci_secure_files/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/distribution.cer>
  - Job SecureFile: 15: Remote object does not exist
Done!

```

누락된 로컬 또는 원격 보안 파일에 대한 이러한 참조를 삭제하려면:

1. [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 열세요.
1. 다음 Ruby 코드를 실행하세요:

   ```ruby
   secure_files_deleted = 0
   ::Ci::SecureFile.find_each do |secure_file|                    ### Iterate secure files
     next if secure_file.file.file.exists?                        ### Skip if the file reference is valid
     secure_files_deleted += 1
     puts "#{secure_file.id}  #{secure_file.file.path} is missing."     ### Allow verification before destroy
   #  secure_file.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{secure_files_deleted}"
   ```
