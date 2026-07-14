---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 설치 문제 해결
description: GitLab 설치 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 페이지는 GitLab 설치 문제를 해결하는 데 도움이 되는 리소스 모음을 제공합니다.

이 목록이 반드시 포괄적이지는 않습니다. 이 목록에서 찾고 있는 항목을 찾을 수 없다면 설명서를 검색해야 합니다.

## 문제 해결 가이드 {#troubleshooting-guides}

- [SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- [Geo](../geo/replication/troubleshooting/_index.md)
- [SAML](../../user/group/saml_sso/troubleshooting.md)
- [Kubernetes 참고서](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [Linux 치트 시트](linux_cheat_sheet.md)
- [`jq`를 사용하여 GitLab 로그 구문 분석](../logs/log_parsing.md)
- [진단 도구](diagnostics_tools.md)

일부 기능 설명서 페이지에는 끝에 문제 해결 섹션이 있으며, 이를 통해 기능별 도움말(유용한 Rails 명령 포함)을 확인할 수 있습니다.

문제를 해결하기 위한 테스트 환경이 필요한 경우 [테스트 환경용 앱](test_environments.md)을 참고하세요.

## 지원 팀 문제 해결 정보 {#support-team-troubleshooting-info}

GitLab 지원 팀은 GitLab 문제 해결에 대한 많은 정보를 수집했습니다. 다음 문서는 지원 팀 또는 지원 팀 담당자의 직접 지도를 받는 고객이 사용합니다. GitLab 관리자는 이 정보가 문제 해결에 유용할 수 있습니다. 그러나 GitLab 인스턴스에 문제가 발생한 경우, 이 문서를 참고하기 전에 [지원 옵션](https://about.gitlab.com/support/)을 확인해야 합니다.

> [!warning]
> 다음 설명서의 명령은 GitLab 인스턴스의 데이터 손실 또는 기타 손상을 야기할 수 있습니다. 이 명령은 위험성을 인식하는 경험 많은 관리자만 사용해야 합니다.

- [진단 도구](diagnostics_tools.md)
- [Linux 명령](linux_cheat_sheet.md)
- [Kubernetes 문제 해결](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)
- [PostgreSQL 문제 해결](postgresql.md)
- [테스트 환경 가이드](test_environments.md)(지원 엔지니어용)
- [SSL 문제 해결](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/)
- 관련 링크:
  - [손상된 Git 리포지토리 복구 및 복원](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [OpenSSL로 테스트](https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html)
  - [`strace` 지인](https://wizardzines.com/zines/strace/)
