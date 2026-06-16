---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Spamcheck 안티스팸 서비스
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!warning]
> 스팸 확인은 모든 계층에서 사용 가능하지만, GitLab Enterprise Edition(EE)을 사용하는 인스턴스에서만 사용할 수 있습니다. [라이선스 관련 사유](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6259#note_726605397)로 인해 GitLab Community Edition(CE) 패키지에는 포함되지 않습니다. [CE에서 EE로 마이그레이션](../../update/convert_to_ee/package.md)할 수 있습니다.

[Spamcheck](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)는 GitLab에서 개발한 안티스팸 엔진으로, 원래 GitLab.com의 증가하는 스팸에 대처하기 위해 개발되었으며 나중에 GitLab 셀프 매니지드 인스턴스에서 사용할 수 있도록 공개되었습니다.

## Spamcheck 활성화 {#enable-spamcheck}

Spamcheck은 패키지 기반 설치에서만 사용할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`을 편집하고 Spamcheck을 활성화합니다:

   ```ruby
   spamcheck['enable'] = true
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 새로운 서비스 `spamcheck`과 `spam-classifier`이 실행 중인지 확인합니다:

   ```shell
   sudo gitlab-ctl status
   ```

## Spamcheck을 사용하도록 GitLab 구성 {#configure-gitlab-to-use-spamcheck}

전제 조건:

- 관리자 액세스.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포트**를 선택합니다.
1. **스팸 및 안티봇 보호**를 펼칩니다.
1. 스팸 확인 설정을 업데이트합니다:
   1. "외부 API 엔드포인트를 통한 스팸 확인 활성화" 체크박스를 선택합니다.
   1. **외부 스팸 확인 엔드포인트의 URL**에 `grpc://localhost:8001`을 사용합니다.
   1. **스팸 확인 API 키**를 비워둡니다.
1. **변경사항 저장**을 선택합니다.

> [!note]
> 단일 노드 인스턴스에서 Spamcheck은 `localhost`에서 실행되며, 따라서 인증되지 않은 모드에서 실행됩니다. 여러 노드 인스턴스에서 GitLab이 한 서버에서 실행되고 Spamcheck이 공용 엔드포인트를 통해 수신 대기하는 다른 서버에서 실행되는 경우, API 키와 함께 사용할 수 있는 Spamcheck 서비스 앞에 리버스 프록시를 사용하여 인증을 강제하도록 권장합니다. 한 가지 예는 `JWT` 인증을 사용하고 베어러 토큰을 API 키로 지정하는 것입니다. [Spamcheck에 대한 기본 인증이 진행 중입니다](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck/-/issues/171).

## TLS를 통한 Spamcheck 실행 {#running-spamcheck-over-tls}

Spamcheck 서비스는 자체적으로 GitLab과 TLS를 통해 직접 통신할 수 없습니다. 그러나 Spamcheck은 TLS 종료를 수행하는 리버스 프록시 뒤에 배포할 수 있습니다. 이러한 경우 **운영자** 영역 설정에서 `grpc://` 대신 `tls://` 스킴을 지정하여 GitLab이 TLS를 통해 Spamcheck과 통신하도록 할 수 있습니다.
