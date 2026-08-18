---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 환경 변수
description: 지원되는 환경 변수를 재정의합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 기본값을 재정의하는 데 사용할 수 있는 특정 환경 변수를 노출합니다.

사람들은 일반적으로 다음을 사용하여 GitLab을 구성합니다:

- `/etc/gitlab/gitlab.rb` Linux 패키지 설치용입니다.
- `gitlab.yml` 자체 컴파일된 설치용입니다.

다음 환경 변수를 사용하여 특정 값을 재정의할 수 있습니다:

## 지원되는 환경 변수 {#supported-environment-variables}

| 변수                                     | 유형    | 설명                                                                                                                                                                                                                                                                                                                      |
|----------------------------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DATABASE_URL`                               | 문자열  | 데이터베이스 URL입니다. 형식은 `postgresql://localhost/blog_development`입니다.                                                                                                                                                                                                                                                     |
| `ENABLE_BOOTSNAP`                            | 문자열  | 초기 Rails 부트를 가속화하기 위해 [Bootsnap](https://github.com/Shopify/bootsnap)을 전환합니다. 기본적으로 프로덕션 이외의 환경에서 사용 가능합니다. 비활성화하려면 `0`로 설정합니다.                                                                                                                                                           |
| `EXTERNAL_URL`                               | 문자열  | [설치 시](https://docs.gitlab.com/omnibus/settings/configuration/#specify-the-external-url-at-the-time-of-installation) 외부 URL을 지정합니다.                                                                                                                                                     |
| `EXTERNAL_VALIDATION_SERVICE_TIMEOUT`        | 정수 | [외부 CI/CD 파이프라인 검증 서비스](cicd/external_pipeline_validation.md)의 시간 초과(초)입니다. 기본값은 `5`입니다.                                                                                                                                                                                                  |
| `EXTERNAL_VALIDATION_SERVICE_URL`            | 문자열  | [외부 CI/CD 파이프라인 검증 서비스](cicd/external_pipeline_validation.md)의 URL입니다.                                                                                                                                                                                                                                    |
| `EXTERNAL_VALIDATION_SERVICE_TOKEN`          | 문자열  | [외부 CI/CD 파이프라인 검증 서비스](cicd/external_pipeline_validation.md)로 인증하기 위한 `X-Gitlab-Token`입니다.                                                                                                                                                                                              |
| `GITLAB_CDN_HOST`                            | 문자열  | 정적 자산을 제공하기 위한 CDN의 기본 URL을 설정합니다(예: `https://mycdnsubdomain.fictional-cdn.com`).                                                                                                                                                                                                                    |
| `GITLAB_EMAIL_DISPLAY_NAME`                  | 문자열  | GitLab에서 보낸 이메일의 **시작** 필드에 사용되는 이름입니다.                                                                                                                                                                                                                                                                    |
| `GITLAB_EMAIL_FROM`                          | 문자열  | GitLab에서 보낸 이메일의 **시작** 필드에 사용되는 이메일 주소입니다.                                                                                                                                                                                                                                                           |
| `GITLAB_EMAIL_REPLY_TO`                      | 문자열  | GitLab에서 보낸 이메일의 **Reply-To** 필드에 사용되는 이메일 주소입니다.                                                                                                                                                                                                                                                       |
| `GITLAB_EMAIL_SUBJECT_PREFIX`                | 문자열  | GitLab에서 보낸 이메일에 사용되는 이메일 제목 접두사입니다.                                                                                                                                                                                                                                                                          |
| `GITLAB_EMAIL_SUBJECT_SUFFIX`                | 문자열  | GitLab에서 보낸 이메일에 사용되는 이메일 제목 접미사입니다.                                                                                                                                                                                                                                                                          |
| `GITLAB_HOST`                                | 문자열  | GitLab 서버의 전체 URL (`http://` 또는 `https://` 포함)입니다.                                                                                                                                                                                                                                                           |
| `GITLAB_MARKUP_TIMEOUT`                      | 문자열  | [`gitlab-markup` gem](https://gitlab.com/gitlab-org/gitlab-markup/)에서 실행하는 `rest2html` 및 `pod2html` 명령의 시간 초과(초)입니다. 기본값은 `10`입니다.                                                                                                                                                               |
| `GITLAB_ROOT_PASSWORD`                       | 문자열  | 설치 시 `root` 사용자의 비밀번호를 설정합니다.                                                                                                                                                                                                                                                                           |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN`   | 문자열  | 러너에 사용되는 초기 등록 토큰을 설정합니다. [GitLab 16.11에서 지원 중단됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148310).                                                                                                                                                                                |
| `RAILS_ENV`                                  | 문자열  | Rails 환경입니다. `production`, `development`, `staging` 또는 `test` 중 하나입니다.                                                                                                                                                                                                                                          |
| `GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS`     | 정수 | Rails 캐시에 저장된 항목에 사용되는 기본 TTL입니다. 기본값은 `28800`입니다. [15.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95042).                                                                                                                                                               |
| `GITLAB_CI_CONFIG_FETCH_TIMEOUT_SECONDS`     | 정수 | CI 구성에서 원격 포함을 해결하기 위한 시간 초과(초)입니다. `0`과 `60` 사이여야 합니다. 기본값은 `30`입니다. [15.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116383).                                                                                                                               |
| `GITLAB_CI_CONFIG_GITALY_TIMEOUT_SECONDS`    | 정수 | CI 구성 파일을 가져올 때 Gitaly 호출에 대한 요청별 시간 초과(초)입니다(로컬, 프로젝트 및 구성 요소 포함). 기본값은 `10`입니다.                                                              |
| `GITLAB_CI_CONFIG_HTTP_OPEN_TIMEOUT_SECONDS`  | 정수 | 원격 CI 구성 파일을 가져올 때 HTTP 호출에 대한 요청별 개방(연결) 시간 초과(초)입니다. `1`과 `60` 사이여야 합니다. 기본값은 `10`입니다.                                                                                   |
| `GITLAB_CI_CONFIG_HTTP_READ_TIMEOUT_SECONDS`  | 정수 | 원격 CI 구성 파일을 가져올 때 HTTP 호출에 대한 요청별 읽기 시간 초과(초)입니다. `1`과 `60` 사이여야 합니다. 기본값은 `30`입니다.                                                                                                |
| `GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES` | 정수 | CI 러너에 전송할 수 있는 최대 커밋 메시지 크기(바이트)입니다. `0`과 `1000000` 사이여야 합니다. 기본값은 `100000`입니다. [18.6에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208666).                                                                                                                                                                           |
| `GITLAB_DISABLE_MARKDOWN_TIMEOUT`            | 문자열  | `true`, `1` 또는 `yes`으로 설정하면 백엔드에서 Markdown 렌더링이 시간 초과되지 않습니다. 기본값은 `false`입니다. [17.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163662).                                                                                                                                    |
| `GITLAB_LFS_LINK_BATCH_SIZE`                 | 정수 | LFS 파일 연결의 배치 크기를 설정합니다. 기본값은 `1000`입니다.                                                                                                                                                                                                                                                                    |
| `GITLAB_LFS_MAX_OID_TO_FETCH`                | 정수 | 연결할 LFS 개체의 최대 수를 설정합니다. 기본값은 `100000`입니다.                                                                                                                                                                                                                                                            |
| `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`        | 정수 | Sidekiq 반신뢰 가져오기의 시간 초과를 설정합니다. 기본값은 `5`입니다. [GitLab 16.7 이전](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583)에는 기본값이 `3`였습니다. GitLab 16.6 이전에서 높은 Redis CPU 사용량이 발생하거나 이 변수를 사용자 지정한 경우 이 변수를 `5`로 업데이트해야 합니다. |
| `SSL_IGNORE_UNEXPECTED_EOF`                  | 문자열  | OpenSSL 3.0은 SSL 연결을 종료하기 전에 서버가 `close_notify` 경고를 보내도록 요구합니다. 기본값은 `false`입니다. 이 변수를 `true`로 설정하면 경고가 비활성화됩니다. 자세한 내용은 [OpenSSL 설명서](https://docs.openssl.org/3.0/man3/SSL_CTX_set_options/#notes)를 참조하세요.                                                        |

## 더 많은 변수 추가 {#adding-more-variables}

변수를 사용하여 더 많은 설정을 구성 가능하게 하는 머지 리퀘스트를 환영합니다. `config/initializers/1_settings.rb` 파일을 변경하고 명명 스키마 `GITLAB_#{name in 1_settings.rb in upper case}`를 사용합니다.

## Linux 패키지 설치 구성 {#linux-package-installation-configuration}

환경 변수를 설정하려면 [이 지침](https://docs.gitlab.com/omnibus/settings/environment-variables/)을 따르세요.

`docker run` 명령에 `GITLAB_OMNIBUS_CONFIG` 환경 변수를 추가하여 GitLab Docker 이미지를 미리 구성할 수 있습니다. 자세한 내용은 [Docker 컨테이너 사전 구성](../install/docker/configuration.md#pre-configure-docker-container)을 참조하세요.
