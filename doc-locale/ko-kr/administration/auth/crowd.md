---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Atlassian Crowd를 인증 공급자로 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Atlassian Crowd OmniAuth 공급자를 사용하여 GitLab에 인증합니다. 이 공급자를 활성화하면 Git-over-https 요청에 대해 Crowd 인증을 허용합니다.

## 새로운 Crowd 응용 프로그램 구성 {#configure-a-new-crowd-application}

1. 상단 메뉴에서 **응용 프로그램** > **Add application**를 선택합니다.
1. **Add application** 단계를 진행하며 적절한 세부 정보를 입력합니다.
1. 완료되면 **Add application**를 선택합니다.

## GitLab 구성 {#configure-gitlab}

1. GitLab 서버에서 구성 파일을 엽니다.

   - Linux 패키지 설치:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - 직접 컴파일한 설치:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. [공통 설정](../../integration/omniauth.md#configure-common-settings)을 구성하여 `crowd`을 단일 로그인 제공자로 추가합니다. 이를 통해 기존 GitLab 계정이 없는 사용자를 위한 Just-In-Time 계정 프로비저닝이 활성화됩니다.

1. 제공자 구성을 추가합니다:

   - Linux 패키지 설치:

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "crowd",
           args: {
             crowd_server_url: "CROWD_SERVER_URL",
             application_name: "YOUR_APP_NAME",
             application_password: "YOUR_APP_PASSWORD"
           }
         }
       ]
     ```

   - 직접 컴파일한 설치:

     ```yaml
        - { name: 'crowd',
            args: {
              crowd_server_url: 'CROWD_SERVER_URL',
              application_name: 'YOUR_APP_NAME',
              application_password: 'YOUR_APP_PASSWORD' } }
     ```

1. `CROWD_SERVER_URL`을 [Crowd 서버의 기본 URL](https://confluence.atlassian.com/crowdkb/how-to-change-the-crowd-base-url-245827278.html)로 변경합니다.
1. `YOUR_APP_NAME`을 Crowd 응용 프로그램 페이지의 응용 프로그램 이름으로 변경합니다.
1. `YOUR_APP_PASSWORD`을 설정한 응용 프로그램 암호로 변경합니다.
1. 구성 파일을 저장합니다.
1. [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) (Linux 패키지 설치) 또는 [다시 시작](../restart_gitlab.md#self-compiled-installations)(직접 컴파일한 설치)하여 변경 사항을 적용합니다.

로그인 페이지에 이제 로그인 양식에 Crowd 탭이 있어야 합니다.

## 문제 해결 {#troubleshooting}

### 오류: `could not authorize you from Crowd because invalid credentials` {#error-could-not-authorize-you-from-crowd-because-invalid-credentials}

이 오류는 사용자가 Crowd로 인증을 시도할 때 발생하기도 합니다. Crowd 관리자는 이 오류 메시지의 정확한 원인을 파악하기 위해 Crowd 로그 파일을 확인해야 합니다.

GitLab에 로그인해야 하는 Crowd 사용자가 **Authorization** 단계의 [응용 프로그램](#configure-a-new-crowd-application)에 승인되어 있는지 확인합니다. 이는 Crowd의 "인증 테스트"를 시도하여 확인할 수 있습니다(2.11 기준).

![Crowd의 승인 스테이지 설정](img/crowd_application_authorisation_v10_4.png)
