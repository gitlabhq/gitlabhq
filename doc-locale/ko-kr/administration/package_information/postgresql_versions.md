---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지와 함께 제공되는 PostgreSQL 버전
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> 이 표는 PostgreSQL 버전과 관련하여 패키지에서 중요한 변경 사항이 발생한 GitLab 버전만 나열하며, 모든 버전을 나열하지는 않습니다.

일반적으로 PostgreSQL 버전은 GitLab의 주 버전 또는 부 버전 릴리스와 함께 변경됩니다. 그러나 Linux 패키지의 패치 버전에서 간혹 PostgreSQL의 패치 수준을 업데이트하기도 합니다. GitLab은 PostgreSQL 업그레이드를 위한 연간 주기를 설정했으며, 새 버전이 요구되기 이전 릴리스에서 자동 데이터베이스 업그레이드를 트리거합니다.

예를 들어:

- Linux 패키지 12.7.6은 PostgreSQL 9.6.14 및 10.9와 함께 제공되었습니다.
- Linux 패키지 12.7.7은 PostgreSQL 9.6.17 및 10.12와 함께 제공되었습니다.

각 Linux 패키지 릴리스와 함께 [제공되는 PostgreSQL(및 기타 구성 요소) 버전을 확인](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)하세요.

지원되는 최소 PostgreSQL 버전은 [설치 요구 사항](../../install/requirements.md#postgresql)에 나열되어 있습니다.

업데이트 정책 및 경고에 대한 자세한 내용은 PostgreSQL [업그레이드 문서](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)를 참조하세요.

| 최초 GitLab 버전 | PostgreSQL 버전 | 새로 설치를 위한 기본 버전 | 업그레이드를 위한 기본 버전 | 참고 |
| -------------- | ------------------- | ---------------------------------- | ---------------------------- | ----- |
| 19.3.0 | 17.10, 18.4 | 17.10 | 17.10 | PostgreSQL 18.4는 새로운 설치에 대한 선택적 옵션으로 제공됩니다. |
| 19.0.0 | 17.8 | 17.8 | 17.8 | PostgreSQL을 이미 17로 업그레이드하지 않으면 패키지 업그레이드가 중단됩니다. |
| 18.11.0 | 16.11, 17.7 | 17.7 | 17.7 | 새로 설치는 기본적으로 PostgreSQL 17을 사용합니다. [옵트아웃](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)하지 않는 한, Linux 패키지 인스턴스 업그레이드 시 Geo 또는 HA 클러스터의 일부가 아닌 노드에 대해 자동으로 PostgreSQL 17 업그레이드가 수행됩니다. |
| 18.4.1, 18.3.3, 18.2.7 | 16.10 | 16.10 | 16.10 | |
| 18.0.0 | 16.8 | 16.8 | 16.8 | PostgreSQL이 16으로 사전 업그레이드되어 있지 않으면 패키지 업그레이드가 중단됩니다. |
| 17.11.0 | 14.17, 16.8 | 16.8 | 16.8 | [옵트아웃](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)하지 않는 한, 패키지 업그레이드 시 Geo 또는 HA 클러스터의 일부가 아닌 노드에 대해 자동으로 PostgreSQL 16 업그레이드가 수행됩니다. |
| 17.10.0 | 14.17, 16.8 | 16.8 | 16.8 | 이제 새로 설치 시 기본적으로 PostgreSQL 16을 사용합니다. |
| 17.9.2, 17.8.5, 17.7.7 | 14.17, 16.8 | 14.17 | 16.8 | |
| 17.8.0 | 14.15, 16.6 | 14.15 | 16.6 | |
| 17.5.0 | 14.11, 16.4 | 14.11 | 16.4 | 이제 단일 노드에서 PostgreSQL 14를 16으로 업그레이드하는 것이 지원됩니다. GitLab 17.5.0부터 Geo 배포 환경의 새로 설치 및 업그레이드 모두에 대해 PostgreSQL 16이 완벽히 지원됩니다(17.4.0의 제한 사항이 더 이상 적용되지 않음). |
| 17.4.0 | 14.11, 16.4 | 14.11 | 14.11 | [Geo](../geo/_index.md#requirements-for-running-geo) 또는 [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)를 사용하지 않는 경우 새로 설치 시 PostgreSQL 16을 사용할 수 있습니다. |
| 17.0.0 | 14.11 | 14.11 | 14.11 | PostgreSQL이 14로 사전 업그레이드되어 있지 않으면 패키지 업그레이드가 중단됩니다. |
| 16.10.1, 16.9.3, 16.8.5 | 13.14, 14.11 | 14.11 | 14.11 | |
| 16.6.7, 16.7.5, 16.8.2 | 13.13, 14.10 | 14.10 | 14.10 | |
| 16.7.0 | 13.12, 14.9 | 14.9 | 14.9 | |
| 16.4.3, 16.5.3, 16.6.1 | 13.12, 14.9 | 13.12 | 13.12 | 업그레이드의 경우 [업그레이드 설명서](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)를 따라 14.9로 수동 업그레이드할 수 있습니다. |
| 16.2.0 | 13.11, 14.8 | 13.11 | 13.11 | 업그레이드의 경우 [업그레이드 설명서](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)를 따라 14.8로 수동 업그레이드할 수 있습니다. |
| 16.0.2 | 13.11 | 13.11 | 13.11 | |
| 16.0.0 | 13.8  | 13.8  | 13.8  | |
| 15.11.7 | 13.11 | 13.11 | 12.12 | |
| 15.10.8 | 13.11 | 13.11 | 12.12 | |
| 15.6 | 12.12, 13.8 | 13.8 | 12.12 | 업그레이드의 경우 [업그레이드 설명서](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)를 따라 13.8로 수동 업그레이드할 수 있습니다. |
| 15.0 | 12.10, 13.6 | 13.6 | 12.10 | 업그레이드의 경우 [업그레이드 설명서](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)를 따라 13.6으로 수동 업그레이드할 수 있습니다. |
| 14.1 | 12.7, 13.3 | 12.7 | 12.7 | [Geo](../geo/_index.md#requirements-for-running-geo) 또는 [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)를 사용하지 않는 경우 새로 설치 시 PostgreSQL 13을 사용할 수 있습니다. |
| 14.0 | 12.7       | 12.7 | 12.7 | repmgr을 사용하는 HA 설치는 더 이상 지원되지 않으며 Linux 패키지 14.0으로 업그레이드는 차단됩니다. |
| 13.8 | 11.9, 12.4 | 12.4 | 12.4 | 패키지 업그레이드는 Geo 또는 HA 클러스터의 일부가 아닌 노드에 대해 PostgreSQL 업그레이드를 자동으로 수행합니다. |
| 13.7 | 11.9, 12.4 | 12.4 | 11.9 | 업그레이드의 경우 사용자는 [업그레이드 설명서](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)를 따라 12.4로 수동 업그레이드할 수 있습니다. |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | PostgreSQL 11을 이미 실행 중이 아니면 패키지 업그레이드가 중단됩니다. |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | PostgreSQL 11을 이미 실행 중이 아니면 패키지 업그레이드가 중단됩니다. |
| 13.0 | 11.7 | 11.7 | 11.7 | PostgreSQL 11을 이미 실행 중이 아니면 패키지 업그레이드가 중단됩니다. |
| 12.10 | 9.6.17, 10.12, 및 11.7 | 11.7 | 11.7 | 패키지 업그레이드는 Geo 또는 repmgr 클러스터의 일부가 아닌 노드에 대해 PostgreSQL 업그레이드를 자동으로 수행합니다. |
| 12.8 | 9.6.17, 10.12, 및 11.7 | 10.12 | 10.12 | 사용자는 업그레이드 설명서를 따라 11.7로 수동 업그레이드할 수 있습니다. |
| 12.0 | 9.6.11 및 10.7 | 10.7 | 10.7 | 패키지 업그레이드는 PostgreSQL 업그레이드를 자동으로 수행합니다. |
| 11.11 | 9.6.11 및 10.7 | 9.6.11 | 9.6.11 | 사용자는 업그레이드 설명서를 따라 10.7로 수동 업그레이드할 수 있습니다. |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | 사용자가 여전히 9.2를 사용 중이면 패키지 업그레이드가 중단됩니다. |
| 9.0 | 9.2.18 및 9.6.1 | 9.6.1 | 9.6.1 | 패키지 업그레이드는 PostgreSQL 업그레이드를 자동으로 수행합니다. |
| 8.14 | 9.2.18 및 9.6.1 | 9.2.18 | 9.2.18 | 사용자는 업그레이드 설명서를 9.6으로 수동 업그레이드할 수 있습니다. |
