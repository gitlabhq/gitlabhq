---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD에서 SCP를 통한 배포를 사용하여 Composer 및 npm 스크립트 실행
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 가이드는 [GitLab CI/CD](../../_index.md)를 사용하여 npm 스크립트를 통해 자산을 컴파일하면서 PHP 프로젝트의 종속성을 빌드하는 방법을 다룹니다.

사용자 지정 PHP 및 Node.js 버전으로 자신의 이미지를 만들 수 있습니다. 간단히 하기 위해 이 가이드는 PHP와 Node.js가 모두 설치된 기존 [Docker 이미지](https://hub.docker.com/r/tetraweb/php/)를 사용합니다.

```yaml
image: tetraweb/php
```

다음 단계는 zip/unzip 패키지를 설치하고 composer를 사용 가능하게 하는 것입니다. 이를 `before_script` 섹션에 배치합니다:

```yaml
before_script:
  - apt-get update
  - apt-get install zip unzip
  - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  - php composer-setup.php
  - php -r "unlink('composer-setup.php');"
```

이는 모든 요구 사항이 준비되었는지 확인합니다. 다음으로 `composer install`를 실행하여 모든 PHP 종속성을 가져오고 `npm install`를 실행하여 Node.js 패키지를 로드합니다. 그런 다음 `npm` 스크립트를 실행합니다. 명령을 `before_script` 섹션에 추가합니다:

```yaml
before_script:
  # ...
  - php composer.phar install
  - npm install
  - npm run deploy
```

이 경우 `npm deploy` 스크립트는 다음을 수행하는 Gulp 스크립트입니다:

1. CSS 및 JS 컴파일
1. 스프라이트 생성
1. 다양한 자산(이미지, 글꼴) 복사
1. 일부 문자열 바꾸기

이 모든 작업은 모든 파일을 `build` 폴더에 넣으며, 이는 라이브 서버에 배포할 준비가 됩니다.

## 라이브 서버로 파일을 전송하는 방법 {#how-to-transfer-files-to-a-live-server}

rsync, SCP, SFTP 등 여러 옵션이 있습니다. 지금은 SCP를 사용합니다.

이를 작동시키려면 GitLab CI/CD 변수를 추가해야 합니다(`gitlab.example/your-project-name/variables`에서 액세스 가능). 이 변수를 `STAGING_PRIVATE_KEY`로 이름 지정하고 서버의 **비공개** SSH 키로 설정합니다.

### 보안 팁 {#security-tip}

업데이트해야 하는 폴더에 **only** 액세스할 수 있는 사용자를 만듭니다.

해당 변수를 생성한 후 해당 키가 실행 시 Docker 컨테이너에 추가되었는지 확인합니다:

```yaml
before_script:
  # - ....
  - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
  - mkdir -p ~/.ssh
  - eval $(ssh-agent -s)
  - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
```

이 스크립트는 다음 작업을 수행합니다:

1. `ssh-agent`이 사용 가능한지 확인하고 그렇지 않으면 설치합니다.
1. `~/.ssh` 폴더를 만듭니다.
1. 스크립트 실행 환경이 bash를 실행 중인지 확인합니다.
1. 호스트 확인을 비활성화합니다. 모든 연결이 새로운 환경에서 발생하므로 호스트 확인을 비활성화하면 GitLab이 매번 연결하기 전에 사용자에게 서버의 신원을 확인하고 수락하도록 요청하지 않습니다.

이는 기본적으로 `before_script` 섹션에 필요한 모든 것입니다.

## 배포 방법 {#how-to-deploy}

`build` 폴더를 Docker 이미지에서 서버로 배포하려면 새 작업을 만듭니다:

```yaml
stage_deploy:
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```

다음은 분석입니다:

1. `rules:if: $CI_COMMIT_BRANCH == "dev"`은 `dev` 브랜치로 푸시된 경우에만 이 빌드가 실행됨을 의미합니다. 이 블록을 완전히 제거하고 모든 푸시에서 실행되도록 할 수 있습니다(하지만 아마도 이는 원하지 않는 것일 것입니다).
1. `ssh-add ...`은 웹 UI에서 추가한 프로젝트 키를 Docker 컨테이너에 추가합니다.
1. `ssh`을 사용하여 연결하고 새 `_tmp` 폴더를 만듭니다.
1. `scp`을 사용하여 연결하고 `build` 폴더(`npm` 스크립트로 생성됨)를 이전에 생성된 `_tmp` 폴더에 업로드합니다.
1. `ssh`을 사용하여 다시 연결하고 `live` 폴더를 `_old` 폴더로 이동한 후 `_tmp`를 `live`로 이동합니다.
1. SSH로 연결하고 `_old` 폴더를 제거합니다.

`artifacts` 섹션은 GitLab CI/CD에 `build` 디렉터리를 유지하도록 지시합니다(나중에 필요에 따라 다운로드할 수 있습니다).

### 왜 이런 방식으로 할까요 {#why-do-it-this-way}

이를 스테이지 서버에만 사용하는 경우 두 단계로 수행할 수 있습니다:

```yaml
- ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/live/*"
- scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/live
```

문제는 서버에 앱이 없는 짧은 시간 주기가 있다는 것입니다.

따라서 프로덕션 환경에서 추가 단계는 기능하는 앱이 항상 제 위치에 있음을 보장합니다.

## 다음으로 어디로 이동할까요 {#where-to-go-next}

이것이 WordPress 프로젝트였기 때문에 실제 코드 스니펫이 포함되어 있습니다. 따를 수 있는 몇 가지 추가 아이디어:

- 기본 브랜치에 대해 약간 다른 스크립트를 사용하면 해당 브랜치에서 프로덕션 서버로 배포하고 다른 브랜치에서 스테이지 서버로 배포할 수 있습니다.
- 라이브로 푸시하는 대신 WordPress 공식 리포지토리로 푸시할 수 있습니다.
- i18n 텍스트 도메인을 즉시 생성할 수 있습니다.

---

최종 `.gitlab-ci.yml`은 다음과 같습니다:

```yaml
stage_deploy:
  image: tetraweb/php
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  before_script:
    - apt-get update
    - apt-get install zip unzip
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php
    - php -r "unlink('composer-setup.php');"
    - php composer.phar install
    - npm install
    - npm run deploy
    - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
    - mkdir -p ~/.ssh
    - eval $(ssh-agent -s)
    - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```
