---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자산 프록시
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

공개 GitLab 인스턴스를 관리할 때 가능한 보안 문제는 이슈와 댓글에서 이미지를 참조하여 사용자의 IP 주소를 도용할 수 있다는 점입니다.

예를 들어 `![An example image.](http://example.com/example.png)`을(를) 이슈 설명에 추가하면 외부 서버에서 이미지를 로드하여 표시되도록 합니다. 그러나 이는 외부 서버가 사용자의 IP 주소를 기록할 수 있도록 허용합니다.

이를 완화하는 한 가지 방법은 외부 이미지를 제어하는 서버로 프록시하는 것입니다.

GitLab은 이슈와 댓글의 외부 이미지/동영상/오디오를 요청할 때 자산 프록시 서버를 사용하도록 구성할 수 있습니다. 이는 악의적인 이미지가 가져올 때 사용자의 IP 주소를 노출하지 않도록 보장하는 데 도움이 됩니다.

현재 [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works)를 사용할 것을 권장합니다. 동영상, 오디오 프록시를 지원하며 더 구성하기 쉽기 때문입니다.

## Camo 서버 설치 {#installing-camo-server}

Camo 서버는 프록시 역할을 합니다.

Camo 서버를 자산 프록시로 설치하려면:

1. `go-camo` 서버를 배포합니다. 유용한 지침은 [cactus/go-camo 빌드](https://github.com/cactus/go-camo#building)에서 찾을 수 있습니다.

   > [!warning]
   > 자산 프록시 서버는 올바른 Content Security Policy 헤더(예: `form-action 'none'`, 기본 `go-camo` 헤더 포함)를 사용하도록 구성해야 합니다.

1. GitLab 인스턴스가 실행 중이고 개인 API 토큰을 생성했는지 확인하세요. API를 사용하여 GitLab 인스턴스의 자산 프록시 설정을 구성합니다. 예를 들어:

   ```shell
   curl --request "PUT" "https://gitlab.example.com/api/v4/application/settings?\
   asset_proxy_enabled=true&\
   asset_proxy_url=https://proxy.gitlab.example.com&\
   asset_proxy_secret_key=<somekey>" \
   --header 'PRIVATE-TOKEN: <my_private_token>'
   ```

   다음 설정이 지원됩니다:

   | 속성                | 설명                                                                                                                          |
   |:-------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
   | `asset_proxy_enabled`    | 자산 프록시를 활성화합니다. 활성화된 경우 필수: `asset_proxy_url`.                                                                  |
   | `asset_proxy_secret_key` | 자산 프록시 서버와 공유하는 비밀입니다.                                                                                           |
   | `asset_proxy_url`        | 자산 프록시 서버의 URL입니다.                                                                                                       |
   | `asset_proxy_whitelist`  | (더 이상 사용되지 않음: 대신 `asset_proxy_allowlist`을(를) 사용하세요) 이러한 도메인과 일치하는 자산은 프록시되지 않습니다. 와일드카드가 허용됩니다. GitLab 설치 URL은 자동으로 허용됩니다.         |
   | `asset_proxy_allowlist`  | 이러한 도메인과 일치하는 자산은 프록시되지 않습니다. 와일드카드가 허용됩니다. GitLab 설치 URL은 자동으로 허용됩니다.         |

1. 변경 사항을 적용하려면 서버를 다시 시작합니다. 자산 프록시의 값을 변경할 때마다 서버를 다시 시작해야 합니다.

## Camo 서버 사용 {#using-the-camo-server}

Camo 서버가 실행 중이고 GitLab 설정을 활성화한 후에는 외부 소스를 참조하는 모든 이미지, 동영상 또는 오디오가 Camo 서버로 프록시됩니다.

예를 들어 다음은 Markdown의 이미지에 대한 링크입니다:

```markdown
![A GitLab logo.](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

다음은 발생할 수 있는 소스 링크의 예입니다:

```plaintext
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
