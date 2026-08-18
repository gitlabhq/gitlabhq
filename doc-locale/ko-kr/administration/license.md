---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Enterprise Edition (EE)을 활성화하여 Premium 및 Ultimate 기능을 잠금 해제합니다. 활성화 단계, 라이선스 옵션 및 문제 해결 팁을 알아봅니다."
title: GitLab Enterprise Edition (EE) 활성화
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

라이선스 없이 새로운 GitLab 인스턴스를 설치하면 Free 기능만 활성화됩니다. GitLab Enterprise Edition (EE)에서 더 많은 기능을 활성화하려면 활성화 코드로 인스턴스를 활성화합니다.

## GitLab EE 활성화 {#activate-gitlab-ee}

전제 조건:

- [구독](https://about.gitlab.com/pricing/).
- GitLab Enterprise Edition (EE).
- 인스턴스가 인터넷에 연결되어 있습니다.
- 관리자 액세스 권한이 있어야 합니다.

활성화 코드로 인스턴스를 활성화하려면:

1. 24자의 영숫자 문자열인 활성화 코드를 다음 중 하나에서 복사합니다:
   - 구독 확인 이메일.
   - [Customers Portal](https://customers.gitlab.com/customers/sign_in)의 **Manage Purchases** 페이지에서.
1. 인스턴스에 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.
1. **활성화 코드**에 활성화 코드를 붙여넣습니다.
1. 서비스 약관을 읽고 동의합니다.
1. **활성화**를 선택합니다.

구독이 활성화됩니다.

### 여러 인스턴스에 하나의 활성화 코드 사용 {#using-one-activation-code-for-multiple-instances}

다음 경우에 여러 GitLab Self-Managed 인스턴스에 단일 활성화 코드 또는 라이선스 키를 사용할 수 있습니다:

- 라이선스가 있는 프로덕션 인스턴스와 동일합니다.
- 라이선스가 있는 프로덕션 인스턴스의 부분 집합입니다.

활성화 코드는 그룹 및 프로젝트에서 사용자를 구성하는 방식에 관계없이 이러한 인스턴스에 대해 유효합니다.

### 확장된 아키텍처의 경우 {#for-scaled-architectures}

확장된 아키텍처에서 인스턴스를 활성화하려면:

- 라이선스 파일을 하나의 애플리케이션 인스턴스에만 업로드합니다.

라이선스는 데이터베이스에 저장되며 모든 인스턴스로 복제됩니다.

### GitLab Geo의 경우 {#for-gitlab-geo}

GitLab Geo를 사용할 때 인스턴스를 활성화하려면:

- 라이선스를 기본 Geo 인스턴스에 업로드합니다.

라이선스는 데이터베이스에 저장되며 모든 인스턴스로 복제됩니다.

### 오프라인 환경의 경우 {#for-offline-environments}

오프라인 환경에서 인스턴스를 활성화하려면:

- [라이선스 파일 또는 키로 GitLab EE 활성화](license_file.md).

질문이 있거나 인스턴스 활성화에 지원이 필요한 경우 [GitLab Support에 문의](https://about.gitlab.com/support/#contact-support)하세요.

[라이선스가 만료되면](license_file.md#what-happens-when-your-license-expires) 일부 기능이 잠깁니다.

## GitLab 에디션 확인 {#verify-your-gitlab-edition}

에디션을 확인하려면 GitLab에 로그인하고 **도움말** ({{< icon name="question-o" >}}) > **도움말**을 선택합니다. GitLab 에디션 및 버전이 페이지의 상단에 나열됩니다.

GitLab Community Edition (CE)을 실행 중인 경우 설치를 GitLab EE로 업그레이드할 수 있습니다. 자세한 내용은 [다른 업그레이드 경로](../update/convert_to_ee/_index.md)를 참조하세요.

질문이 있거나 지원이 필요한 경우 [GitLab Support에 문의](https://about.gitlab.com/support/#contact-support)하세요.

## 문제 해결 {#troubleshooting}

GitLab Self-Managed 인스턴스에서 유료 구독 기능을 활성화할 때 다음 문제가 발생할 수 있습니다.

### 오류: `An error occurred while adding your subscription` {#error-an-error-occurred-while-adding-your-subscription}

이 문제는 활성화 코드를 입력한 후에 발생할 수 있습니다.

오류에 대한 자세한 내용을 찾으려면 브라우저의 개발자 도구를 사용할 수 있습니다:

1. 개발자 도구를 열려면 페이지를 마우스 오른쪽 버튼으로 클릭하고 **Inspect**를 선택합니다.
1. **네트워크** 탭을 선택합니다.
1. GitLab에서 활성화 코드를 다시 시도합니다.
1. **네트워크** 탭에서 `graphql` 항목을 선택합니다.
1. **반응** 탭을 선택하고 다음과 유사한 오류를 확인합니다:

      ```plaintext
      [{"data":{"gitlabSubscriptionActivate":{"errors":["<error> returned=1 errno=0 state=error: <error>"],"license":null,"__typename":"GitlabSubscriptionActivatePayload"}}}]
      ```

문제를 해결하려면:

- GraphQL 응답에 `only get, head, options, and trace methods are allowed in silent mode`이(가) 포함된 경우 인스턴스에 대해 [자동 모드](silent_mode/_index.md#turn-off-silent-mode)를 비활성화합니다.

문제를 결정할 수 없는 경우 [GitLab Support](https://about.gitlab.com/support/portal/)에 문의하고 문제 설명에서 GraphQL 응답을 제공합니다.

### 오류: `Cannot activate instance due to a connectivity issue` {#error-cannot-activate-instance-due-to-a-connectivity-issue}

인스턴스를 활성화할 때 GitLab 서버에 대한 연결을 방해하는 연결 문제가 발생할 수 있습니다. 이는 다음과 같은 원인으로 발생할 수 있습니다:

- **Firewall settings**:
  - GitLab 인스턴스가 포트 443에서 `https://customers.gitlab.com`로 암호화된 연결을 설정할 수 있는지 확인하려면 다음 curl 명령을 사용합니다:

    ```shell
    curl --verbose "https://customers.gitlab.com/"
    ```

  - curl 명령이 오류를 반환하면 다음 중 하나를 수행합니다:
    - 방화벽 또는 프록시를 확인합니다. 도메인 `https://customers.gitlab.com`은(는) Cloudflare에서 제공합니다. 방화벽 또는 프록시가 활성화를 위해 Cloudflare [IPv4](https://www.cloudflare.com/ips-v4/) 및 [IPv6](https://www.cloudflare.com/ips-v6/) 범위로의 트래픽을 허용하는지 확인합니다.
    - [프록시 구성](https://docs.gitlab.com/omnibus/settings/environment-variables/)을 `gitlab.rb`에서 서버를 가리키도록 설정합니다.

    기존 프록시 또는 방화벽을 변경하려면 네트워크 관리자에게 문의합니다.
  - SSL 검사 어플라이언스를 사용하는 경우 어플라이언스의 루트 CA 인증서를 인스턴스의 `/etc/gitlab/trusted-certs`에 추가한 후 `gitlab-ctl reconfigure`를 실행합니다.
- **Customers Portal is not operational**:
  - [상태](https://status.gitlab.com/)에서 Customers Portal에 대한 활성 중단을 확인합니다.
- **An offline environment**:
  - [DNS 설정](https://docs.gitlab.com/omnibus/settings/dns/)을 확인합니다.
  - 다음 중 하나에 문의합니다:
    - GitLab 판매 담당자에게 [오프라인 라이선스](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license)를 요청합니다.
    - [GitLab Support](https://about.gitlab.com/support/#contact-support) 에 [네트워크 연결 문제 해결](https://handbook.gitlab.com/handbook/support/license-and-renewals/workflows/self-managed/troubleshoot_cloud_licensing/#troubleshooting-network-connectivity) 지원을 요청합니다.
