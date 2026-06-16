---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SMTP Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음은 SMTP 관련 Rake 작업입니다.

## 보안 정보 {#secrets}

GitLab은 SMTP 구성 보안 정보를 사용하여 암호화된 파일에서 읽을 수 있습니다. 암호화된 파일의 내용을 업데이트하기 위해 다음과 같은 Rake 작업이 제공됩니다.

### 보안 정보 표시 {#show-secret}

현재 SMTP 보안 정보의 내용을 표시합니다.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:show
  ```

- 자체 컴파일된 설치:

  ```shell
  bundle exec rake gitlab:smtp:secret:show RAILS_ENV=production
  ```

**Example output**:

```plaintext
password: '123'
user_name: 'gitlab-inst'
```

### 보안 정보 편집 {#edit-secret}

보안 정보 내용을 편집기에서 열고, 편집기를 종료할 때 결과 내용을 암호화된 보안 정보 파일에 씁니다.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
  ```

- 자체 컴파일된 설치:

  ```shell
  bundle exec rake gitlab:smtp:secret:edit RAILS_ENV=production EDITOR=vim
  ```

### 원본 보안 정보 쓰기 {#write-raw-secret}

`STDIN`에서 제공하여 새로운 보안 정보 내용을 씁니다.

- Linux 패키지 설치:

  ```shell
  echo -e "password: '123'" | sudo gitlab-rake gitlab:smtp:secret:write
  ```

- 자체 컴파일된 설치:

  ```shell
  echo -e "password: '123'" | bundle exec rake gitlab:smtp:secret:write RAILS_ENV=production
  ```

### 보안 정보 예 {#secrets-examples}

**Editor example**

쓰기 작업은 편집 명령이 편집기와 함께 작동하지 않는 경우에 사용할 수 있습니다:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:smtp:secret:show > smtp.yaml
# Edit the smtp file in your editor
...
# Re-encrypt the file
cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
# Remove the plaintext file
rm smtp.yaml
```

**KMS integration example**

KMS로 암호화된 내용을 받는 애플리케이션으로도 사용할 수 있습니다:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:smtp:secret:write
```

**Google Cloud secret integration example**

Google Cloud에서 보안 정보를 받는 애플리케이션으로도 사용할 수 있습니다:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:smtp:secret:write
```
