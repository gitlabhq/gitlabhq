---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AWS Route53를 이용한 위치 인식 Git 원격 URL
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!note]
> [GitLab Geo는 웹 UI 및 API 트래픽을 포함한 위치 인식 DNS를 지원합니다.](../secondary_proxy/_index.md#configure-location-aware-dns) 이 설정은 본 문서에 설명된 위치 인식 Git 원격 URL보다 권장됩니다.

GitLab 사용자에게 자신에게 가장 가까운 Geo 사이트를 자동으로 사용하는 단일 원격 URL을 제공할 수 있습니다. 즉, 사용자는 이동하면서 더 가까운 Geo 사이트를 활용하기 위해 Git 설정을 업데이트할 필요가 없습니다.

Git push 요청은 **세컨더리** 사이트에서 **프라이머리** 사이트로 자동으로 리디렉션(HTTP) 또는 프록시(SSH)될 수 있기 때문에 이것이 가능합니다.

이 지침은 [AWS Route53](https://aws.amazon.com/route53/) 을 사용하지만, [Cloudflare](https://www.cloudflare.com/)와 같은 다른 서비스도 사용할 수 있습니다.

## 필수 요구 사항 {#prerequisites}

이 예제에서는 이미 다음을 설정했습니다:

- `primary.example.com`을 Geo **프라이머리** 사이트로 설정합니다.
- `secondary.example.com`을 Geo **세컨더리** 사이트로 설정합니다.

`git.example.com` 서브도메인을 생성하여 요청을 자동으로 리디렉션합니다:

- 유럽에서 **세컨더리** 사이트로 리디렉션합니다.
- 다른 모든 위치에서 **프라이머리** 사이트로 리디렉션합니다.

어쨌든 다음이 필요합니다:

- 자신의 주소에서 접근할 수 있는 GitLab **프라이머리** 사이트.
- 작동하는 GitLab **세컨더리** 사이트.
- 도메인을 관리하는 Route53 호스팅 영역.

Geo 프라이머리 사이트와 세컨더리 사이트를 아직 설정하지 않았다면, [Geo 설정 지침](../setup/_index.md)을 참조하세요.

## 트래픽 정책 생성 {#create-a-traffic-policy}

Route53 호스팅 영역에서 트래픽 정책을 사용하여 다양한 라우팅 설정을 구성할 수 있습니다.

1. [Route53 대시보드](https://console.aws.amazon.com/route53/home)로 이동하여 **Traffic policies**을 선택합니다.

   ![Route53 대시보드의 트래픽 정책 섹션](img/single_git_traffic_policies_v12_3.png)

1. **Create traffic policy**을 선택합니다.

   ![트래픽 정책 명명](img/single_git_name_policy_v12_3.png)

1. **정책 이름** 필드를 `Single Git Host`로 채우고 **다음**을 선택합니다.

   ![트래픽 정책의 DNS 유형 선택](img/single_git_policy_diagram_v12_3.png)

1. **DNS type**을 `A: IP Address in IPv4 format`으로 유지합니다.
1. **Connect to**을 선택하고 **Geolocation rule**을 선택합니다.

   ![지리 위치 규칙 추가](img/single_git_add_geolocation_rule_v12_3.png)

1. 첫 번째 **위치**는 `Default`로 유지합니다.
1. **Connect to**을 선택하고 **New endpoint**를 선택합니다.
1. **유형** `value`을 선택하고 `<your **primary** IP address>`으로 채웁니다.
1. 두 번째 **위치**는 `Europe`을 선택합니다.
1. **Connect to**을 선택하고 **New endpoint**를 선택합니다.
1. **유형** `value`을 선택하고 `<your **secondary** IP address>`으로 채웁니다.

   ![지리 위치 규칙에 위치 및 엔드포인트 설정](img/single_git_add_traffic_policy_endpoints_v12_3.png)

1. **Create traffic policy**을 선택합니다.

   ![트래픽 정책에서 정책 기록 설정](img/single_git_create_policy_records_with_traffic_policy_v12_3.png)

1. **Policy record DNS name**을 `git`으로 채웁니다.
1. **Create policy records**을 선택합니다.

   ![트래픽 정책과 정책 기록이 성공적으로 생성됨](img/single_git_created_policy_record_v12_3.png)

단일 호스트(예: `git.example.com`)를 성공적으로 설정하여 지리 위치에 따라 Geo 사이트로 트래픽을 분산합니다!

## 특수 Git URL을 사용하도록 Git 클론 URL 구성 {#configure-git-clone-urls-to-use-the-special-git-url}

사용자가 처음으로 리포지토리를 복제할 때, 일반적으로 프로젝트 페이지에서 Git 원격 URL을 복사합니다. 기본적으로 이러한 SSH 및 HTTP URL은 현재 호스트의 외부 URL을 기반으로 합니다. 예를 들어:

- `git@secondary.example.com:group1/project1.git`
- `https://secondary.example.com/group1/project1.git`

![리포지토리의 SSH 및 HTTPS URL](img/single_git_clone_panel_v12_3.png)

다음을 사용자 지정할 수 있습니다:

- 위치 인식 `git.example.com`을 사용하려면 SSH 원격 URL을 사용합니다. 이렇게 하려면 웹 노드의 `gitlab.rb`에서 `gitlab_rails['gitlab_ssh_host']`을 설정하여 SSH 원격 URL 호스트를 변경합니다.
- [HTTP(S)용 사용자 지정 Git 클론 URL](../../settings/visibility_and_access_controls.md#customize-git-clone-url-for-https)에 표시된 HTTP 원격 URL.

## Git 요청 처리 동작 예제 {#example-git-request-handling-behavior}

이전에 문서화된 설정 단계를 따른 후 Git 요청의 처리는 이제 위치를 인식합니다. 요청의 경우:

- 유럽 외부의 모든 요청은 **프라이머리** 사이트로 리디렉션됩니다.
- 유럽 내에서는 다음을 통해:
  - HTTP:
    - `git clone http://git.example.com/foo/bar.git`은 **세컨더리** 사이트로 리디렉션됩니다.
    - `git push`은 처음에는 **세컨더리**로 리디렉션되었다가 자동으로 `primary.example.com`으로 리디렉션됩니다.
  - SSH:
    - `git clone git@git.example.com:foo/bar.git`은 **세컨더리**로 리디렉션됩니다.
    - `git push`은 처음에는 **세컨더리**로 리디렉션되었다가 자동으로 `primary.example.com`으로 요청을 프록시합니다.
