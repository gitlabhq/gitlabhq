---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: LDAP Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음은 LDAP 관련 Rake 작업입니다.

## 확인 {#check}

LDAP 확인 Rake 작업은 `bind_dn`과 `password` 자격 증명(구성된 경우)을 테스트하고 LDAP 사용자의 샘플을 나열합니다. 이 작업은 `gitlab:check` 작업의 일부로도 실행되지만 아래 명령을 사용하여 독립적으로 실행할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:check
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:check
```

{{< /tab >}}

{{< /tabs >}}

기본적으로 작업은 100명의 LDAP 사용자 샘플을 반환합니다. 확인 작업에 숫자를 전달하여 이 제한을 변경하세요:

```shell
rake gitlab:ldap:check[50]
```

## 그룹 동기화 실행 {#run-a-group-sync}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 작업은 [그룹 동기화](../auth/ldap/ldap_synchronization.md#group-sync)를 즉시 실행합니다. 이는 다음 예약된 그룹 동기화 실행을 기다리지 않고 구성된 모든 그룹 멤버십을 LDAP에 대해 업데이트하려는 경우 유용합니다.

> [!note]
> 그룹 동기화가 수행되는 빈도를 변경하려면 대신 [cron 일정을 조정](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule)하세요.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< /tabs >}}

## 공급자 이름 바꾸기 {#rename-a-provider}

`gitlab.yml` 또는 `gitlab.rb`에서 LDAP 서버 ID를 변경하면 모든 사용자 ID를 업데이트하거나 사용자가 로그인할 수 없습니다. 이전 및 새 공급자를 입력하면 이 작업이 데이터베이스의 모든 일치하는 ID를 업데이트합니다.

`old_provider`과 `new_provider`는 접두사 `ldap`과 구성 파일의 LDAP 서버 ID에서 파생됩니다. 예를 들어 `gitlab.yml` 또는 `gitlab.rb`에서 다음과 같은 LDAP 구성을 볼 수 있습니다:

```yaml
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  # ...
```

`main`은 LDAP 서버 ID입니다. 함께 고유 공급자는 `ldapmain`입니다.

> [!warning]
> 잘못된 새 공급자를 입력하면 사용자가 로그인할 수 없습니다. 이 경우 잘못된 공급자를 `old_provider`로, 올바른 공급자를 `new_provider`로 사용하여 작업을 다시 실행하세요.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< /tabs >}}

### 예제 {#example}

기본 서버 ID `main`(전체 공급자 `ldapmain`)부터 시작하는 것을 고려하세요. `main`을 `mycompany`로 변경하면 `new_provider`는 `ldapmycompany`입니다. 모든 사용자 ID의 이름을 바꾸려면 다음 명령을 실행하세요:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapmain,ldapmycompany]
```

출력 예:

```plaintext
100 users with provider 'ldapmain' will be updated to 'ldapmycompany'.
If the new provider is incorrect, users will be unable to sign in.
Do you want to continue (yes/no)? yes

User identities were successfully updated
```

### 기타 옵션 {#other-options}

`old_provider`과 `new_provider`를 지정하지 않으면 작업에서 입력을 요청합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< /tabs >}}

**Example output**:

```plaintext
What is the old provider? Ex. 'ldapmain': ldapmain
What is the new provider? Ex. 'ldapcustom': ldapmycompany
```

이 작업은 또한 `force` 환경 변수를 수락하며, 이는 확인 대화를 건너뜁니다:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider] force=yes
```

## 보안 정보 {#secrets}

GitLab은 [LDAP 구성 보안 정보](../auth/ldap/_index.md#use-encrypted-credentials)를 사용하여 암호화된 파일에서 읽을 수 있습니다. 암호화된 파일의 내용을 업데이트하기 위해 다음과 같은 Rake 작업이 제공됩니다.

### 보안 정보 표시 {#show-secret}

현재 LDAP 보안 정보의 내용을 표시합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< /tabs >}}

**Example output**:

```plaintext
main:
  password: '123'
  bind_dn: 'gitlab-adm'
```

### 보안 정보 편집 {#edit-secret}

보안 정보 내용을 편집기에서 열고, 편집기를 종료할 때 결과 내용을 암호화된 보안 정보 파일에 씁니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
sudo RAILS_ENV=production EDITOR=vim -u git -H bundle exec rake gitlab:ldap:secret:edit
```

{{< /tab >}}

{{< /tabs >}}

### 원본 보안 정보 쓰기 {#write-raw-secret}

STDIN에 제공하여 새로운 보안 정보 내용을 씁니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo gitlab-rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< /tabs >}}

### 보안 정보 예 {#secrets-examples}

- 편집기 예제:

  쓰기 작업은 편집 명령이 편집기와 함께 작동하지 않는 경우에 사용할 수 있습니다:

  ```shell
  # Write the existing secret to a plaintext file
  sudo gitlab-rake gitlab:ldap:secret:show > ldap.yaml
  # Edit the ldap file in your editor
  ...
  # Re-encrypt the file
  cat ldap.yaml | sudo gitlab-rake gitlab:ldap:secret:write
  # Remove the plaintext file
  rm ldap.yaml
  ```

- KMS 통합 예제:

  KMS로 암호화된 내용을 받는 애플리케이션으로도 사용할 수 있습니다:

  ```shell
  gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:ldap:secret:write
  ```

- Google Cloud 보안 정보 통합 예제:

  Google Cloud에서 보안 정보를 받는 애플리케이션으로도 사용할 수 있습니다:

  ```shell
  gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:ldap:secret:write
  ```
