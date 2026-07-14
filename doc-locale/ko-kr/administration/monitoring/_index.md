---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "성능, 상태, 가동 시간 모니터링입니다."
title: GitLab 모니터링
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스를 모니터링할 수 있는 기능을 살펴봅니다:

- [성능 모니터링](performance/_index.md):  GitLab 성능 모니터링을 통해 인스턴스의 다양한 통계를 측정할 수 있습니다.
- [Prometheus](prometheus/_index.md):  Prometheus는 강력한 시계열 모니터링 서비스로, GitLab 및 기타 소프트웨어 제품을 모니터링하기 위한 유연한 플랫폼을 제공합니다.
- [GitHub 가져오기](github_imports.md):  다양한 Prometheus 메트릭을 사용하여 GitHub 가져오기의 상태와 진행 상황을 모니터링합니다.
- [가동 시간 모니터링](health_check.md):  상태 확인 엔드포인트를 사용하여 서버 상태를 확인합니다.
  - [IP 허용 목록](ip_allowlist.md):  프로브될 때 상태 확인 정보를 제공하는 모니터링 엔드포인트에 대해 GitLab을 구성합니다.
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx/#enablingdisabling-nginx_status):  NGINX 서버 상태를 모니터링합니다.
