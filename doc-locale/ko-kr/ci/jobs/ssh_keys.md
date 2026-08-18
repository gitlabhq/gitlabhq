---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD와 함께 SSH 키 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 빌드 환경(러너가 실행되는 위치)에서 SSH 키를 관리하기 위한 기본 제공 지원을 하지 않습니다.

다음의 경우 SSH 키를 사용하세요:

- 내부 서브모듈을 확인합니다.
- 패키지 관리자를 사용하여 비공개 패키지를 다운로드합니다. 예를 들어 Bundler입니다.
- 응용 프로그램을 사용자 고유의 서버 또는 예를 들어 Heroku에 배포합니다.
- 빌드 환경에서 원격 서버로 SSH 명령을 실행합니다.
- 빌드 환경에서 원격 서버로 파일을 Rsync합니다.

가장 널리 지원되는 방법은 `.gitlab-ci.yml`을 확장하여 SSH 키를 빌드 환경에 주입하는 것입니다. 이 접근 방식은 Docker 또는 셸과 같은 모든 유형의 [실행기](https://docs.gitlab.com/runner/executors/)에서 작동합니다.

> [!note]
> CI/CD에서 SSH 키를 사용할 때는 비공개 키를 안전하게 저장하고 자동화된 작업에 대해 개인 SSH 키를 재사용하지 마세요. 무단 액세스의 위험을 줄이기 위해 키를 정기적으로 회전하세요.

## SSH 키 생성 및 사용 {#create-and-use-an-ssh-key}

GitLab CI/CD에서 SSH 키를 생성하고 사용하려면:

1. [새 SSH 키 쌍 생성](../../user/ssh.md#generate-an-ssh-key-pair).
1. 비공개 키를 [file type CI/CD variable](#add-an-ssh-key-as-a-file-type-variable) 이름으로 추가합니다 `SSH_PRIVATE_KEY`.
1. 작업에서 [`ssh-agent`](https://linux.die.net/man/1/ssh-agent)을 실행하여 비공개 키를 로드합니다.
1. 공개 키를 액세스 권한을 원하는 서버(일반적으로 `~/.ssh/authorized_keys`)에 복사합니다. 비공개 GitLab 리포지토리에 액세스하는 경우 공개 키를 [배포 키](../../user/project/deploy_keys/_index.md)로도 추가해야 합니다.

다음 예에서 `ssh-add -` 명령은 작업 로그에 `$SSH_PRIVATE_KEY`의 값을 표시하지 않지만 [디버그 로깅](../variables/variables_troubleshooting.md#enable-debug-logging)을 활성화하면 노출될 수 있습니다. [파이프라인의 가시성](../pipelines/settings.md#change-which-users-can-view-your-pipelines)을 확인할 수도 있습니다.

### 파일 유형 변수로 SSH 키 추가 {#add-an-ssh-key-as-a-file-type-variable}

프로젝트에 SSH 키를 추가하려면 키를 [file type CI/CD variable](../variables/_index.md#for-a-project)로 추가하세요:

1. **공개범위**를 **표시**로 설정하세요.

   > [!note]
   > 공개범위 설정은 SSH 키에 공백 문자가 포함되어 있고 **표시** 또는 **마스킹 및 숨김** 변수가 공백 문자를 포함할 수 없기 때문에 **마스킹됨**으로 설정해야 합니다. `cat` 또는 `tee` 같은 명령을 변수에서 실행하지 마세요. SSH 키가 작업 로그에 나타나면 마스킹되지 않기 때문입니다.

1. **키** 텍스트 상자에 변수 이름을 입력하세요. 예를 들어, `SSH_PRIVATE_KEY`입니다.
1. **값** 텍스트 상자에 비공개 키 콘텐츠를 붙여넣으세요. 값은 줄 바꿈(`LF` 문자)으로 끝나야 합니다. 줄 바꿈을 추가하려면 저장하기 전에 마지막 줄의 끝에서 <kbd>Enter</kbd> 또는 <kbd>Return</kbd>을 누르세요.

### 일반 변수로 SSH 키 추가 {#add-an-ssh-key-as-a-regular-variable}

파일 유형 CI/CD 변수를 사용하지 않으려면 [SSH 프로젝트 예제](https://gitlab.com/gitlab-examples/ssh-private-key/)를 참조하세요. 이 방법은 파일 유형 변수 대신 일반 CI/CD 변수를 사용합니다. 일반적으로 파일 유형 변수는 여러 줄 서식을 유지하고 서식 관련 오류의 위험을 줄이기 때문에 선호됩니다.

## Docker 실행기를 사용할 때 SSH 키 {#ssh-keys-when-using-the-docker-executor}

CI/CD 작업이 Docker 컨테이너에서 실행되면 환경이 격리됩니다. 코드를 비공개 서버에 배포하려면 SSH 키 쌍을 사용할 수 있습니다.

1. [새 SSH 키 쌍 생성](../../user/ssh.md#generate-an-ssh-key-pair). SSH 키에 암호를 추가하지 마세요. 그렇지 않으면 `before_script`에서 암호를 요청합니다.
1. 비공개 키를 [file type CI/CD variable](#add-an-ssh-key-as-a-file-type-variable) 이름으로 추가합니다 `SSH_PRIVATE_KEY`.
1. 귀사의 `.gitlab-ci.yml`을 `before_script` 작업으로 수정하세요. 다음 예는 Debian 기반 이미지를 가정하며 작업이 패키지를 설치할 권한이 있는 컨테이너에서 실행됩니다.

   ```yaml
   before_script:
     ##
     ## Install ssh-agent if not already installed, it is required by Docker.
     ## (change apt-get to yum if you use an RPM-based image)
     ##
     - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'

     ##
     ## Run ssh-agent (inside the build environment)
     ##
     - eval $(ssh-agent -s)

     ##
     ## Give the right permissions, otherwise ssh-add will refuse to add files
     ## Add the SSH key stored in SSH_PRIVATE_KEY file type CI/CD variable to the agent store
     ##
     - chmod 400 "$SSH_PRIVATE_KEY"
     - ssh-add "$SSH_PRIVATE_KEY"

     ##
     ## Create the SSH directory and give it the right permissions
     ##
     - mkdir -p ~/.ssh
     - chmod 700 ~/.ssh

     ##
     ## Optionally, if you use Git commands, set the user name and email.
     ##
     # - git config --global user.email "user@example.com"
     # - git config --global user.name "User name"
   ```

   [`before_script`](../yaml/_index.md#before_script)은 기본값 또는 작업별로 설정할 수 있습니다.

1. 비공개 서버의 [SSH 호스트 키가 검증](#verifying-the-ssh-host-keys)되었는지 확인하세요.
1. 마지막 단계로 첫 번째 단계에서 생성한 공개 키를 빌드 환경 내부에서 액세스하려는 서비스에 추가합니다. 비공개 GitLab 리포지토리에 액세스하는 경우 [배포 키](../../user/project/deploy_keys/_index.md)로 추가해야 합니다.

완료되었습니다! 이제 빌드 환경에서 비공개 서버 또는 리포지토리에 액세스할 수 있습니다.

## 셸 실행기를 사용할 때 SSH 키 {#ssh-keys-when-using-the-shell-executor}

셸 실행기를 사용 중이고 Docker를 사용하지 않으면 SSH 키를 설정하기가 더 쉽습니다.

러너가 설치된 머신에서 SSH 키를 생성할 수 있으며 이 머신에서 실행되는 모든 project에 해당 키를 사용할 수 있습니다.

1. 먼저 작업을 실행하는 서버에 로그인하세요.
1. 그런 다음 터미널에서 `gitlab-runner` 사용자로 로그인하세요:

   ```shell
   sudo su - gitlab-runner
   ```

1. [새 SSH 키 쌍 생성](../../user/ssh.md#generate-an-ssh-key-pair). SSH 키에 암호를 추가하지 마세요. 그렇지 않으면 `before_script`에서 암호를 요청합니다.
1. 마지막 단계로 앞서 생성한 공개 키를 빌드 환경 내부에서 액세스하려는 서비스에 추가합니다. 비공개 GitLab 리포지토리에 액세스하는 경우 [배포 키](../../user/project/deploy_keys/_index.md)로 추가해야 합니다.

키를 생성한 후 지문을 허용하려면 원격 서버에 로그인을 시도하세요:

```shell
ssh example.com
```

GitLab.com의 리포지토리에 액세스하려면 `git@gitlab.com`을 사용하세요.

## SSH 호스트 키 검증 {#verifying-the-ssh-host-keys}

비공개 서버의 자체 공개 키를 확인하여 중간자 공격의 대상이 되지 않도록 하는 것이 좋습니다. 의심할 만한 일이 발생하면 작업이 실패하기 때문에 알 수 있습니다(공개 키가 일치하지 않으면 SSH 연결이 실패함).

서버의 호스트 키를 찾으려면 신뢰할 수 있는 네트워크(이상적으로는 비공개 서버 자체에서)에서 `ssh-keyscan` 명령을 실행하세요:

```shell
## Use the domain name
ssh-keyscan example.com

## Or use an IP
ssh-keyscan 10.0.2.2
```

호스트를 프로젝트에 [file type CI/CD variable](#add-an-ssh-key-as-a-file-type-variable)로 추가하세요. 단, 다음을 제외합니다:

- `SSH_KNOWN_HOSTS`을 **키**로 사용하세요.
- `ssh-keyscan`의 출력을 **값**으로 사용하세요.

여러 서버에 연결해야 하는 경우 모든 서버 호스트 키를 변수의 **값**에 수집해야 하며, 각 키는 한 줄씩입니다.

> [!note]
> file type CI/CD variable 대신 `ssh-keyscan`을 `.gitlab-ci.yml` 내부에 직접 사용하면 어떤 이유로 호스트 도메인 이름이 변경되어도 `.gitlab-ci.yml`을 변경할 필요가 없다는 이점이 있습니다. 또한 값은 귀사에서 미리 정의되어 있으므로 호스트 키가 갑자기 변경되면 CI/CD 작업이 실패하지 않습니다. 따라서 서버 또는 네트워크에 문제가 있습니다.
>
> CI/CD 작업에서 `ssh-keyscan`을 직접 실행하지 마세요. 이는 중간자 공격에 취약한 보안 위험입니다.

`SSH_KNOWN_HOSTS` 변수가 생성되면 [`.gitlab-ci.yml`의 콘텐츠](#ssh-keys-when-using-the-docker-executor)에 추가로 다음을 추가해야 합니다:

```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS file type CI/CD variable:
  ##
  - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts
```

## 문제 해결 {#troubleshooting}

### 오류: `... error in libcrypto` {#error--error-in-libcrypto}

CI/CD 작업에서 SSH 키를 로드할 때 다음 오류가 발생할 수 있습니다:

```plaintext
Error loading key "/builds/path/SSH_PRIVATE_KEY": error in libcrypto
```

이 이슈는 SSH 키 값이 줄 바꿈(`LF` 문자)으로 끝나지 않을 때 발생할 수 있습니다.

이 이슈를 해결하려면 [file type CI/CD variable](../variables/_index.md#use-file-type-cicd-variables)를 편집하고 변수를 저장하기 전에 SSH 키의 `-----END OPENSSH PRIVATE KEY-----` 줄 끝에서 <kbd>Enter</kbd> 또는 <kbd>Return</kbd>을 누르세요.

### 오류: `... value cannot contain...` {#error--value-cannot-contain}

SSH 키를 CI/CD 변수로 저장할 때 오류가 발생할 수 있습니다:

```plaintext
Unable to create masked variable because: The value cannot contain the
following characters: whitespace characters.
```

이 이슈는 변수 **공개범위**가 **마스킹됨** 또는 **마스킹 및 숨김**으로 설정되어 있을 때 발생합니다. 마스킹된 변수는 공백이 없는 한 줄이어야 하지만 SSH 키에는 마스킹과 호환되지 않는 공백 문자가 포함되어 있습니다.

이 이슈를 해결하려면 [SSH 키를 파일 유형 변수로 추가](#add-an-ssh-key-as-a-file-type-variable)할 때 **공개범위**를 **표시**로 설정하세요. 파일 유형 변수는 작업 로그에 노출되지 않으므로 키 값에 대한 추가 보호 계층을 제공합니다.
