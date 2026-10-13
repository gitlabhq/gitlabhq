---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 플로우가 CI/CD에서 어떻게 실행되는지 구성하는 에이전트 구성 파일의 지원되는 키에 대한 참고자료입니다.
title: 에이전트 구성 파일 구문
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`agent-config.yml` 파일은 프로젝트에서 플로우가 CI/CD로 실행되는 방식을 구성합니다. 프로젝트 리포지토리에 파일을 `.gitlab/duo/agent-config.yml`에 배치합니다.

사용 방법에 대한 자세한 내용은 [플로우 실행 구성](_index.md)을 참고하세요.

> [!note]
> 구성 파일은 프로젝트의 기본 브랜치에서만 읽기 전용입니다. 다른 브랜치에 커밋된 파일은 무시되며, 해당 브랜치에서 플로우가 실행되는 경우에도 마찬가지입니다.

## 지원되는 키 {#supported-keys}

| 키 | 형식 | 설명 |
|-----|------|-------------|
| `image` | 문자열 | 플로우 실행에 사용할 Docker 이미지입니다. 최소 1자, 최대 512자입니다. |
| `setup_script` | 문자열 또는 문자열 배열 | 플로우가 시작되기 전에 실행할 셸 명령입니다. |
| `network_policy` | 객체 | 실행 환경에 대한 네트워크 접근 규칙입니다. 자세한 내용은 [네트워크 정책 구성](../../environment_sandbox.md#configure-a-network-policy)을 참고하세요. |
| `network_policy.allowed_domains` | 문자열 배열 | 플로우가 접근할 수 있는 도메인입니다. 최대 1000개 항목입니다. |
| `network_policy.denied_domains` | 문자열 배열 | 플로우가 접근할 수 없는 도메인입니다. 최대 1000개 항목입니다. |
| `network_policy.include_recommended_allowed` | 부울 | GitLab에서 권장하는 허용된 도메인을 포함합니다. 기본값: `false` |
| `network_policy.allow_all_unix_sockets` | 부울 | 모든 Unix 소켓 연결을 허용합니다. 기본값: `false` |
| `cache` | 객체 | 플로우 실행 사이에 유지할 파일 및 디렉터리입니다. 자세한 내용은 [캐싱 구성](_index.md#configure-caching)을 참고하세요. |
| `cache.paths` | 문자열 또는 문자열 배열 | 캐시할 경로입니다. 캐싱이 적용되려면 필수입니다. |
| `cache.key` | 문자열 또는 객체 | 캐시 키입니다. 생략하면 기본 키가 사용됩니다. |
| `cache.key.files` | 문자열 배열 | SHA 기반 캐시 키를 생성하는 데 사용되는 파일입니다. 최대 2개 파일입니다. |
| `cache.key.prefix` | 문자열 | 파일 SHA와 결합하여 캐시 키를 형성하는 접두사입니다. `files`이 필요합니다. |

## 전체 예시 {#complete-example}

다음 예시는 사용 가능한 모든 구성 옵션을 사용합니다:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```
