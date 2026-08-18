---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Helm 패키지 클라이언트](../../user/packages/helm_repository/_index.md)와 상호작용합니다.

> [!warning]
> 이 API는 [Helm](https://helm.sh/) 및 [`helm-push`](https://github.com/chartmuseum/helm-push/#readme)과 같은 Helm 관련 패키지 클라이언트에서 사용되며, 일반적으로 수동 소비를 위해 설계되지 않았습니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 세부 정보는 [Helm 레지스트리 설명서](../../user/packages/helm_repository/_index.md)를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 차트 인덱스 다운로드 {#download-a-chart-index}

> [!note]
> 일관된 차트 다운로드 URL을 보장하기 위해 `contextPath` 필드의 `index.yaml` 응답은 프로젝트 ID를 사용하는지 또는 전체 프로젝트 경로를 사용하는지 여부에 관계없이 항상 숫자 프로젝트 ID를 사용합니다.

프로젝트의 지정된 차트 인덱스를 다운로드합니다.

```plaintext
GET projects/:id/packages/helm/:channel/index.yaml
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `channel` | 문자열 | 예      | Helm 리포지토리 채널입니다. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml"
```

파일에 출력을 작성합니다:

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml" \
     --remote-name
```

## 차트 다운로드 {#download-a-chart}

프로젝트의 지정된 차트를 다운로드합니다.

```plaintext
GET projects/:id/packages/helm/:channel/charts/:file_name.tgz
```

| 속성   | 유형   | 필수 | 설명 |
| ----------- | ------ | -------- | ----------- |
| `id`        | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `channel`   | 문자열 | 예      | Helm 리포지토리 채널입니다. |
| `file_name` | 문자열 | 예      | 차트 파일 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/charts/mychart.tgz" \
     --remote-name
```

## 차트 업로드 {#upload-a-chart}

프로젝트의 지정된 차트를 업로드합니다.

```plaintext
POST projects/:id/packages/helm/api/:channel/charts
```

| 속성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다. |
| `channel` | 문자열 | 예      | Helm 리포지토리 채널입니다. |
| `chart`   | 파일   | 예      | 차트(`multipart/form-data`로 제공)입니다. |

```shell
curl --request POST \
     --form 'chart=@mychart.tgz' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts"
```
