---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패키지 정보
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Linux 패키지에는 GitLab이 올바르게 작동하는 데 필요한 모든 종속성이 포함되어 있습니다. 자세한 내용은 [번들 종속성 문서](omnibus_packages.md)에서 확인할 수 있습니다.

## 패키지 버전 {#package-version}

릴리스된 패키지 버전의 형식은 `MAJOR.MINOR.PATCH-EDITION.OMNIBUS_RELEASE`입니다.

| 구성 요소           | 의미                                                                                                                                   | 예시  |
|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| `MAJOR.MINOR.PATCH` | 이 항목이 해당하는 GitLab 버전입니다.                                                                                                   | `13.3.0` |
| `EDITION`           | 이 항목이 해당하는 GitLab 에디션입니다.                                                                                                | `ee`     |
| `OMNIBUS_RELEASE`   | Linux 패키지 릴리스입니다. 일반적으로 `0`입니다. GitLab 버전을 변경하지 않고 새 패키지를 빌드해야 하는 경우 이를 증가시킵니다. | `0`      |

## 라이선스 {#licenses}

[라이선싱](licensing.md) 참조

## 기본값 {#defaults}

Linux 패키지는 구성 요소가 작동하는 상태로 만들기 위해 다양한 구성이 필요합니다. 구성을 제공하지 않으면 패키지는 패키지에서 가정하는 기본값을 사용합니다.

이러한 기본값은 패키지 [기본값 문서](defaults.md)에 명시되어 있습니다.

## 번들 소프트웨어 버전 확인 {#checking-the-versions-of-bundled-software}

Linux 패키지를 설치한 후 `/opt/gitlab/version-manifest.txt`에서 GitLab 및 모든 번들 라이브러리의 버전을 확인할 수 있습니다.

패키지가 설치되지 않은 경우 항상 Linux 패키지 [소스 리포지토리](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master) 를 확인할 수 있으며, 특히 [구성 디렉터리](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/config)를 확인할 수 있습니다.

예를 들어 `8-6-stable` 브랜치를 살펴보면 8.6 패키지가 [Ruby 2.1.8](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-6-stable/config/projects/gitlab.rb#L48)을 실행 중이었다고 결론지을 수 있습니다. 또는 8.5 패키지가 [NGINX 1.9.0](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/8-5-stable/config/software/nginx.rb#L20)과 함께 번들되었습니다.

## GitLab, Inc. 제공 패키지의 서명 {#signatures-of-gitlab-inc-provided-packages}

패키지 서명에 대한 문서는 [서명된 패키지](signed_packages.md)에서 확인할 수 있습니다.

## 업그레이드할 때 새 구성 옵션 확인 {#checking-for-newer-configuration-options-on-upgrade}

`/etc/gitlab/gitlab.rb` 구성 파일은 Linux 패키지가 처음 설치될 때 생성됩니다. 사용자 구성의 실수로 인한 덮어쓰기를 피하기 위해 Linux 패키지 설치를 업그레이드할 때 `/etc/gitlab/gitlab.rb` 구성 파일이 새 구성으로 업데이트되지 않습니다.

새 구성 옵션은 [`gitlab.rb.template` 파일](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/files/gitlab-config-template/gitlab.rb.template)에 명시되어 있습니다.

Linux 패키지는 또한 기존 사용자 구성을 패키지에 포함된 최신 버전의 템플릿과 비교하는 편의 명령을 제공합니다.

구성 파일과 최신 버전 간의 차이를 확인하려면 다음을 실행하세요:

```shell
sudo gitlab-ctl diff-config
```

> [!warning]
> 이 명령의 출력을 `/etc/gitlab/gitlab.rb` 구성 파일에 붙여넣을 때 각 줄의 앞에 있는 `+`와 `-` 문자를 생략하세요.

## Init 시스템 감지 {#init-system-detection}

Linux 패키지는 기본 시스템을 쿼리하여 사용하는 init 시스템을 확인하려고 시도합니다. 이는 `WARNING` 실행 중에 `sudo gitlab-ctl reconfigure`로 나타납니다.

init 시스템에 따라 이 `WARNING`은(는) 다음 중 하나일 수 있습니다:

```plaintext
/sbin/init: unrecognized option '--version'
```

기본 init 시스템이 upstart가 아닐 때입니다.

```plaintext
  -.mount loaded active mounted   /
```

기본 init 시스템이 systemd일 때입니다.

이러한 경고는 안전하게 무시할 수 있습니다. 이들이 억제되지 않는 이유는 모든 사람이 가능한 감지 문제를 더 빠르게 디버그할 수 있기 때문입니다.
