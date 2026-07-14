---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages
description: 저장소에서 자동 CI/CD 배포로 정적 웹사이트를 게시합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Pages는 GitLab의 리포지토리에서 정적 웹사이트를 직접 게시합니다.

이러한 웹사이트는:

- GitLab CI/CD 파이프라인으로 자동 배포됩니다.
- 정적 사이트 생성기(Hugo, Jekyll, Gatsby 등) 또는 순수 HTML, CSS, JavaScript, Wasm을 지원합니다.
- 추가 비용 없이 GitLab 제공 인프라에서 실행됩니다.
- 사용자 지정 도메인 및 SSL/TLS 인증서와 연결합니다.
- 기본 제공 인증을 통해 액세스를 제어합니다.
- 개인, 비즈니스 또는 프로젝트 문서 사이트를 안정적으로 확장합니다.

Pages를 사용하여 웹사이트를 게시하려면 Gatsby, Jekyll, Hugo, Middleman, Harp, Hexo, Brunch 같은 정적 사이트 생성기를 사용하세요. Pages는 순수 HTML, CSS, JavaScript, Wasm으로 작성된 웹사이트도 지원합니다. 동적 서버 측 처리(예: `.php`, `.asp`)는 지원되지 않습니다. 자세한 내용은 [정적 웹사이트와 동적 웹사이트](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-1-dynamic-x-static/)를 참조하세요.

## 시작하기 {#getting-started}

GitLab Pages 웹사이트를 만들려면:

| 문서                                                                             | 설명                                                                                  |
|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [GitLab UI를 사용하여 간단한 `.gitlab-ci.yml` 만들기](getting_started/pages_ui.md) | 기존 프로젝트에 Pages 사이트를 추가합니다. UI를 사용하여 간단한 `.gitlab-ci.yml`을 설정하세요.     |
| [`.gitlab-ci.yml` 파일을 처음부터 만들기](getting_started/pages_from_scratch.md) | 기존 프로젝트에 Pages 사이트를 추가합니다. 자신의 CI 파일을 만들고 구성하는 방법을 배웁니다. |
| [`.gitlab-ci.yml` 템플릿 사용](getting_started/pages_ci_cd_template.md)           | 기존 프로젝트에 Pages 사이트를 추가합니다. 미리 작성된 CI 템플릿 파일을 사용합니다.               |
| [샘플 프로젝트 포크하기](getting_started/pages_forked_sample_project.md)              | 샘플 프로젝트를 포크하여 Pages가 이미 구성된 새 프로젝트를 만듭니다.              |
| [프로젝트 템플릿 사용](getting_started/pages_new_project_template.md)              | 템플릿을 사용하여 Pages가 이미 구성된 새 프로젝트를 만듭니다.                      |

GitLab Pages 웹사이트를 업데이트하려면:

| 문서 | 설명 |
|----------|-------------|
| [GitLab Pages 도메인 이름, URL, 기본 URL](getting_started_part_one.md) | GitLab Pages 기본 도메인에 대해 알아봅니다. |
| [GitLab Pages 살펴보기](introduction.md) | 요구 사항, 기술적 측면, 특정 GitLab CI/CD 구성 옵션, 액세스 제어, 사용자 지정 404 페이지, 제한 사항, FAQ. |
| [사용자 지정 도메인 및 SSL/TLS 인증서](custom_domains_ssl_tls_certification/_index.md) | 사용자 지정 도메인 및 하위 도메인, DNS 레코드, SSL/TLS 인증서. |
| [Let's Encrypt 통합](custom_domains_ssl_tls_certification/lets_encrypt_integration.md) | GitLab이 자동으로 획득하고 갱신하는 Let's Encrypt 인증서로 Pages 사이트를 보호합니다. |
| [리다이렉트](redirects.md) | HTTP 리다이렉트를 설정하여 한 페이지를 다른 페이지로 전달합니다. |

자세한 정보는 다음을 참조하세요.

| 문서 | 설명 |
|----------|-------------|
| [정적 웹사이트와 동적 웹사이트](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-1-dynamic-x-static/) | 정적 웹사이트와 동적 웹사이트 개요. |
| [최신 정적 사이트 생성기](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-2/) | SSG 개요. |
| [GitLab Pages를 사용하여 모든 SSG 사이트 구축](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-3-examples-ci/) | GitLab Pages용 SSG를 사용합니다. |

## GitLab Pages 사용 {#using-gitlab-pages}

GitLab Pages를 사용하려면 웹사이트 파일을 업로드할 프로젝트를 GitLab에 만들어야 합니다. 이러한 프로젝트는 공개, 내부 또는 비공개일 수 있습니다.

기본적으로 GitLab은 리포지토리의 `public`이라는 특정 폴더에서 웹사이트를 배포합니다. [Pages로 배포할 사용자 지정 폴더를 설정](introduction.md#customize-the-default-folder)할 수도 있습니다. GitLab에서 새 프로젝트를 만들 때 [리포지토리](../repository/_index.md)가 자동으로 사용 가능하게 됩니다.

사이트를 배포하기 위해 GitLab은 [GitLab CI/CD](../../../ci/_index.md)라는 기본 제공 도구를 사용하여 사이트를 빌드하고 GitLab Pages 서버에 게시합니다. GitLab CI/CD가 이 작업을 수행하기 위해 실행하는 스크립트 시퀀스는 `.gitlab-ci.yml`이라는 파일에서 생성되며, 이를 [만들고 수정](getting_started/pages_from_scratch.md)할 수 있습니다. 구성 파일의 `job` 속성이 있는 사용자 정의 `pages: true`는 GitLab이 GitLab Pages 웹사이트를 배포하고 있다는 것을 인식하게 합니다.

GitLab [Pages 웹사이트의 기본 도메인](getting_started_part_one.md#gitlab-pages-default-domain-names)인 `*.gitlab.io` 또는 자신의 도메인(`example.com`)을 사용할 수 있습니다. 이 경우 도메인 등록 기관(또는 제어판)에서 관리자여야 Pages로 설정할 수 있습니다.

## Pages 사이트에 대한 액세스 {#access-to-your-pages-site}

GitLab Pages 기본 도메인(`.gitlab.io`)을 사용하는 경우 웹사이트가 자동으로 보호되고 HTTPS 아래에서 사용 가능합니다. 자신의 사용자 지정 도메인을 사용하는 경우 선택적으로 SSL/TLS 인증서로 보호할 수 있습니다.

GitLab.com을 사용하는 경우 웹사이트는 인터넷에 공개적으로 사용 가능합니다. 웹사이트에 대한 액세스를 제한하려면 [GitLab Pages 액세스 제어](pages_access_control.md)를 활성화하세요.

GitLab Self-Managed 인스턴스를 사용하는 경우 웹사이트는 시스템 관리자가 선택한 [Pages 설정](../../../administration/pages/_index.md)에 따라 자신의 서버에 게시되며, 시스템 관리자가 웹사이트를 공개 또는 내부로 설정할 수 있습니다.

## Pages 예제 {#pages-examples}

이러한 GitLab Pages 웹사이트 예제는 자신의 필요에 맞게 사용하고 조정할 고급 기술을 제공합니다.

- [iOS에서 GitLab Pages 블로그에 게시](https://about.gitlab.com/blog/posting-to-your-gitlab-pages-blog-from-ios/).
- [GitLab CI: 작업을 순차적으로, 병렬로 실행하거나 사용자 지정 파이프라인 구축](https://about.gitlab.com/blog/basics-of-gitlab-ci-updated/).
- [GitLab CI: 배포 및 환경](https://about.gitlab.com/blog/ci-deployment-and-environments/).
- [Nanoc, GitLab CI, GitLab Pages로 새로운 GitLab 문서 사이트 구축](https://about.gitlab.com/blog/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/).
- [GitLab Pages로 코드 커버리지 보고서 게시](https://about.gitlab.com/blog/publish-code-coverage-report-with-gitlab-pages/).

## GitLab Self-Managed 인스턴스를 위한 GitLab Pages 관리 {#administer-gitlab-pages-for-gitlab-self-managed-instances}

GitLab Self-Managed 인스턴스를 실행하는 경우 [관리 단계를 따르세요](../../../administration/pages/_index.md)에 따라 Pages를 구성합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab Pages 관리 시작 방법에 대한 [동영상 튜토리얼](https://www.youtube.com/watch?v=dD8c7WNcc6s)을 시청하세요.

### Helm 차트(Kubernetes) 인스턴스에서 GitLab Pages 구성 {#configure-gitlab-pages-in-a-helm-chart-kubernetes-instance}

Helm 차트(Kubernetes)로 배포된 인스턴스에서 GitLab Pages를 구성하려면 다음 중 하나를 사용합니다.

- [`gitlab-pages` 서브차트](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/).
- [외부 GitLab Pages 인스턴스](https://docs.gitlab.com/charts/advanced/external-gitlab-pages/).

## GitLab Pages 보안 {#security-for-gitlab-pages}

### `.`을 포함하는 네임스페이스 {#namespaces-that-contain-}

사용자 이름이 `example`인 경우 GitLab Pages 웹사이트는 `example.gitlab.io`에 있습니다. GitLab은 사용자 이름에 `.`을 포함하도록 허용하므로 `bar.example`라는 사용자가 `bar.example.gitlab.io`인 GitLab Pages 웹사이트를 만들 수 있으며, 이는 효과적으로 `example.gitlab.io` 웹사이트의 하위 도메인입니다. 웹사이트에 대해 JavaScript로 쿠키를 설정하는 경우 주의하세요. JavaScript로 쿠키를 안전하게 수동으로 설정하는 방법은 `domain`을 지정하지 않는 것입니다.

```javascript
// Safe: This cookie is only visible to example.gitlab.io
document.cookie = "key=value";

// Unsafe: This cookie is visible to example.gitlab.io and its subdomains,
// regardless of the presence of the leading dot.
document.cookie = "key=value;domain=.example.gitlab.io";
document.cookie = "key=value;domain=example.gitlab.io";
```

이 문제는 사용자 지정 도메인이 있는 사용자나 JavaScript로 쿠키를 수동으로 설정하지 않는 사용자에게는 영향을 주지 않습니다.

### 공유 쿠키 {#shared-cookies}

기본적으로 그룹의 모든 프로젝트는 동일한 도메인(예: `group.gitlab.io`)을 공유합니다. 이는 그룹의 모든 프로젝트에 대해 쿠키도 공유된다는 의미입니다.

각 프로젝트가 다른 쿠키를 사용하도록 보장하려면 프로젝트에 대해 Pages [고유 도메인](#unique-domains) 기능을 활성화하세요.

## 고유 도메인 {#unique-domains}

{{< history >}}

- GitLab 15.9에 [도입](https://gitlab.com/groups/gitlab-org/-/epics/9347)되었으며 [플래그](../../../administration/feature_flags/_index.md) `pages_unique_domain`이름이 지정되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.11에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/388151)됩니다.
- GitLab 16.3에서 [기능 플래그 제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122229)됩니다.
- GitLab 17.4에서 고유 도메인 URL을 더 짧게 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523)합니다.

{{< /history >}}

기본적으로 모든 새 프로젝트는 동일한 그룹의 프로젝트가 쿠키를 공유하지 않도록 Pages 고유 도메인을 사용합니다.

프로젝트 유지 관리자는 다음에서 이 기능을 비활성화할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **Pages**를 선택합니다.
1. **고유 도메인 사용** 체크박스를 선택 해제합니다.
1. **변경사항 저장**을 선택합니다.

예제 URL은 [GitLab Pages 기본 도메인 이름](getting_started_part_one.md#gitlab-pages-default-domain-names)을 참조하세요.

## 기본 도메인 {#primary-domain}

{{< history >}}

- GitLab 17.8에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)되었습니다.

{{< /history >}}

GitLab Pages를 사용자 지정 도메인과 함께 사용하는 경우 모든 요청을 기본 도메인으로 리다이렉트할 수 있습니다. 기본 도메인을 선택하면 사용자는 `308 Permanent Redirect` 상태를 수신하며, 이는 브라우저를 선택한 기본 도메인으로 리다이렉트합니다. 브라우저는 이 리다이렉트를 캐시할 수 있습니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.
- [사용자 지정 도메인](custom_domains_ssl_tls_certification/_index.md#set-up-a-custom-domain)을 설정해야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **Pages**를 선택합니다.
1. **기본 도메인** 드롭다운 목록에서 리다이렉트할 도메인을 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 배포 만료 {#expiring-deployments}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162826)되었습니다.
- GitLab 17.11에서 변수에 대한 지원이 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/492289)되었습니다.

{{< /history >}}

Pages 배포를 [`pages.expire_in`](../../../ci/yaml/_index.md#pagesexpire_in)에서 기간을 지정하여 일정 시간 후 자동으로 삭제하도록 구성할 수 있습니다.

```yaml
create-pages:
  stage: deploy
  script:
    - ...
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

만료된 배포는 10분마다 실행되는 cron 작업에 의해 중지됩니다. 중지된 배포는 10분마다 실행되는 다른 cron 작업에 의해 이후에 삭제됩니다. 복구하려면 [중지된 배포 복구](#recover-a-stopped-deployment)에 설명된 단계를 따르세요.

중지되거나 삭제된 배포는 더 이상 웹에서 사용할 수 없습니다. 다른 배포가 같은 URL 구성으로 만들어질 때까지 URL에서 404 찾을 수 없음 오류 페이지가 표시됩니다.

이전 YAML 예제는 [사용자 정의 작업 이름](#user-defined-job-names)을 사용합니다.

### 중지된 배포 복구 {#recover-a-stopped-deployment}

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

아직 삭제되지 않은 중지된 배포를 복구하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **Pages**를 선택합니다.
1. **배포** 근처에서 **중지된 배포 포함** 토글을 켭니다. 배포가 아직 삭제되지 않았으면 목록에 포함되어야 합니다.
1. 복구하려는 배포를 확장하고 **복원**을 선택합니다.

### 배포 삭제 {#delete-a-deployment}

배포를 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **Pages**를 선택합니다.
1. **배포** 아래에서 삭제하려는 배포의 아무 영역이나 선택합니다. 배포 세부 정보가 확장됩니다.
1. **삭제**를 선택합니다.

**삭제**를 선택하면 배포가 즉시 중지됩니다. 중지된 배포는 10분마다 실행되는 cron 작업에 의해 삭제됩니다.

아직 삭제되지 않은 중지된 배포를 복구하려면 [중지된 배포 복구](#recover-a-stopped-deployment)를 참조하세요.

## 사용자 정의 작업 이름 {#user-defined-job-names}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/232505)되었으며 `customizable_pages_job_name` 플래그가 기본적으로 비활성화됩니다.
- GitLab 17.6에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169095)합니다. 기능 플래그 `customizable_pages_job_name`이 제거되었습니다.

{{< /history >}}

모든 작업에서 Pages 배포를 트리거하려면 작업 정의에 `pages` 속성을 포함하세요. `true`로 설정된 부울이거나 해시일 수 있습니다.

예를 들어 `true`을 사용하는 경우:

```yaml
deploy-my-pages-site:
  stage: deploy
  script:
    - npm run build
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

예를 들어 해시를 사용하는 경우:

```yaml
deploy-pages-review-app:
  stage: deploy
  script:
    - npm run build
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: '_staging'
```

`pages` 이름의 작업의 `pages` 속성이 `false`로 설정되면 배포가 트리거되지 않습니다.

```yaml
pages:
  pages: false
```

> [!warning]
> 파이프라인에서 `path_prefix`에 대해 동일한 값을 가진 Pages 작업이 여러 개 있으면 완료된 마지막 작업이 Pages로 배포됩니다.

## 병렬 배포 {#parallel-deployments}

예를 들어 검토 앱을 만들기 위해 동시에 프로젝트에 대해 여러 배포를 만들려면 [병렬 배포](parallel_deployments.md)의 문서를 참조하세요.
