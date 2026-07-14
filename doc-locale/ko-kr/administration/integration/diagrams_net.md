---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab을 위한 Diagrams.net 통합을 구성합니다.
gitlab_dedicated: yes
title: Diagrams.net
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 오프라인 환경 지원 [GitLab 16.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116281).

{{< /history >}}

[diagrams.net](https://www.drawio.com/) 통합을 사용하여 위키에서 SVG 다이어그램을 생성하고 포함시킵니다. 다이어그램 편집기는 일반 텍스트 편집기와 리치 텍스트 편집기 모두에서 사용할 수 있습니다.

이 통합은 모든 GitLab.com 사용자가 사용할 수 있으며 추가 구성이 필요하지 않습니다.

GitLab Self-Managed 및 GitLab Dedicated의 경우 무료 [diagrams.net](https://www.drawio.com/) 웹 사이트와 통합하거나 오프라인 환경에서 자체 diagrams.net 사이트를 호스팅합니다.

통합을 설정하려면:

1. 무료 diagrams.net 웹 사이트와 통합하거나 [diagrams.net 서버를 구성](#configure-your-diagramsnet-server)합니다.
1. [통합을 활성화](#enable-diagramsnet-integration)합니다.

통합 완료 후 diagrams.net 편집기가 제공된 URL로 열립니다.

## diagrams.net 서버 구성 {#configure-your-diagramsnet-server}

다이어그램을 생성하기 위해 자체 diagrams.net 서버를 설정할 수 있습니다. GitLab Self-Managed 오프라인 설치의 경우 이 단계는 필수입니다.

Docker에서 diagrams.net 컨테이너를 실행하려면 다음 명령어를 실행합니다:

```shell
docker run -it --rm --name="draw" -p 8006:8080 -p 8443:8443 jgraph/drawio
```

> [!note]
> HTTP 엔드포인트에 포트 `8006`를 사용합니다. 기본 포트 `8080`는 피해야 합니다. [Puma](../operations/puma.md)가 메트릭을 위해 포트 `8080`에서 수신 대기하기 때문입니다.

컨테이너를 실행하는 서버의 호스트 이름을 기록합니다. 통합을 활성화할 때 이 호스트 이름을 diagrams.net URL로 사용합니다.

자세한 내용은 [Docker를 사용하여 자체 diagrams.net 서버 실행](https://www.drawio.com/blog/diagrams-docker-app)을 참조하세요.

## Diagrams.net 통합 활성화 {#enable-diagramsnet-integration}

1. [운영자](../../user/permissions.md) 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **Diagrams.net**을 확장합니다.
1. **Enable Diagrams.net** 확인란을 선택합니다.
1. Diagrams.net URL을 입력합니다. 다음에 연결하려면:
   - 무료 공개 인스턴스: `https://embed.diagrams.net`을(를) 입력합니다.
   - 로컬에 호스팅된 diagrams.net 인스턴스: [이전에 구성한](#configure-your-diagramsnet-server) URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.
