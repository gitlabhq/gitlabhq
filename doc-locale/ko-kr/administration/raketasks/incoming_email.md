---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 수신 이메일 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 15.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279)

{{< /history >}}

다음은 수신 이메일 관련 Rake 작업입니다.

## 비밀번호 {#secrets}

GitLab은 [수신 이메일](../incoming_email.md) 암호를 일반 텍스트로 파일 시스템에 저장하는 대신 암호화된 파일에서 읽을 수 있습니다. 다음은 암호화된 파일의 내용을 업데이트하기 위해 제공되는 Rake 작업입니다.

### 비밀번호 표시 {#show-secret}

현재 수신 이메일 암호의 내용을 표시합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

Kubernetes 암호를 사용하여 수신 이메일 암호를 저장합니다. 자세한 내용은 [Helm IMAP 비밀](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:show RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### 출력 예 {#example-output}

```plaintext
password: 'examplepassword'
user: 'incoming-email@mail.example.com'
```

### 비밀번호 편집 {#edit-secret}

편집기에서 비밀번호 내용을 열고 종료할 때 결과 내용을 암호화된 비밀번호 파일에 씁니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

Kubernetes 암호를 사용하여 수신 이메일 암호를 저장합니다. 자세한 내용은 [Helm IMAP 비밀](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:edit EDITOR=editor
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:edit RAILS_ENV=production EDITOR=vim
```

{{< /tab >}}

{{< /tabs >}}

### 원본 비밀번호 쓰기 {#write-raw-secret}

`STDIN`에 제공하여 새 비밀번호 내용을 씁니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
echo -e "password: 'examplepassword'" | sudo gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

Kubernetes 암호를 사용하여 수신 이메일 암호를 저장합니다. 자세한 내용은 [Helm IMAP 비밀](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> /bin/bash
echo -e "password: 'examplepassword'" | gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
echo -e "password: 'examplepassword'" | bundle exec rake gitlab:incoming_email:secret:write RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### 비밀번호 예제 {#secrets-examples}

**Editor example**

쓰기 작업은 편집 명령이 편집기에서 작동하지 않는 경우에 사용할 수 있습니다:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:incoming_email:secret:show > incoming_email.yaml
# Edit the incoming_email file in your editor
...
# Re-encrypt the file
cat incoming_email.yaml | sudo gitlab-rake gitlab:incoming_email:secret:write
# Remove the plaintext file
rm incoming_email.yaml
```

**KMS integration example**

KMS로 암호화된 내용을 받는 애플리케이션으로도 사용할 수 있습니다:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```

**Google Cloud secret integration example**

Google Cloud에서 나온 비밀을 받는 애플리케이션으로도 사용할 수 있습니다:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```
