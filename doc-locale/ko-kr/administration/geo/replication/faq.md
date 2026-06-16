---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Geo 자주 묻는 질문
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## Geo를 실행하기 위한 최소 요구 사항은 무엇입니까? {#what-are-the-minimum-requirements-to-run-geo}

요구 사항은 [인덱스 페이지](../_index.md#requirements-for-running-geo)에 나열되어 있습니다.

## Geo는 어떤 프로젝트를 동기화할지 어떻게 알 수 있습니까? {#how-does-geo-know-which-projects-to-sync}

각 **세컨더리** 사이트에는 GitLab 데이터베이스의 읽기 전용 복제 복사본이 있습니다. **세컨더리** 사이트에는 어떤 프로젝트가 동기화되었는지 저장하는 추적 데이터베이스도 있습니다. Geo는 두 데이터베이스를 비교하여 아직 추적되지 않은 프로젝트를 찾습니다.

처음에는 이 추적 데이터베이스가 비어 있으므로 Geo는 GitLab 데이터베이스에서 볼 수 있는 모든 프로젝트에서 업데이트를 시도합니다.

동기화할 각 프로젝트의 경우:

1. Geo는 `git fetch geo --mirror`을(를) 실행하여 **프라이머리** 사이트에서 최신 정보를 가져옵니다. 변경 사항이 없으면 동기화가 빠릅니다. 그렇지 않으면 최신 커밋을 가져와야 합니다.
1. **세컨더리** 사이트는 추적 데이터베이스를 업데이트하여 이름으로 작업을 동기화했다는 사실을 저장합니다.
1. 모든 프로젝트가 동기화될 때까지 반복합니다.

누군가가 **프라이머리** 사이트에 커밋을 푸시하면 리포지토리가 변경되었다는 이벤트를 GitLab 데이터베이스에서 생성합니다. **세컨더리** 사이트는 이 이벤트를 확인하고 해당 프로젝트를 더티로 표시한 후 프로젝트를 다시 동기화하도록 예약합니다.

파이프라인 문제(예: 동기화가 너무 많이 실패하거나 작업이 손실됨)로 인해 프로젝트 동기화가 영구적으로 중지되지 않도록 하기 위해 Geo는 또한 더티로 표시된 프로젝트에 대한 추적 데이터베이스를 주기적으로 확인합니다. 이 확인은 동시 동기화 수가 `repos_max_capacity` 아래로 떨어지고 동기화를 기다리는 새 프로젝트가 없을 때 발생합니다.

Geo는 또한 SHA256 합계를 모든 Git 참조에서 SHA 값까지 실행하는 체크섬 기능을 가지고 있습니다. 참조가 **프라이머리** 사이트와 **세컨더리** 사이트 사이에 일치하지 않으면 **세컨더리** 사이트는 해당 프로젝트를 더티로 표시하고 다시 동기화를 시도합니다. 따라서 추적 데이터베이스가 오래되었더라도 검증이 활성화되어야 하고 리포지토리 상태의 불일치를 찾아 다시 동기화합니다.

## 재해 복구 상황에서 Geo를 사용할 수 있습니까? {#can-you-use-geo-in-a-disaster-recovery-situation}

네, 하지만 우리가 복제하는 것에 제한이 있습니다([**세컨더리** 사이트에 복제되는 데이터는 무엇입니까?](#what-data-is-replicated-to-a-secondary-site) 참조).

[재해 복구](../disaster_recovery/_index.md)에 대한 설명서를 읽으세요.

## **세컨더리** 사이트에 복제되는 데이터는 무엇입니까? {#what-data-is-replicated-to-a-secondary-site}

우리는 전체 레일 데이터베이스, 프로젝트 리포지토리, LFS 개체, 생성된 첨부 파일, 아바타 등을 복제합니다. 이는 사용자 계정, 이슈, 머지 리퀘스트, 그룹 및 프로젝트 데이터와 같은 정보를 쿼리할 수 있음을 의미합니다.

Geo에서 복제한 데이터의 포괄적인 목록은 [지원되는 Geo 데이터 유형 페이지](datatypes.md)를 참조하세요.

## `git push`을(를) **세컨더리** 사이트로 할 수 있습니까? {#can-i-git-push-to-a-secondary-site}

**세컨더리** 사이트로 직접 푸시하기(HTTP 및 SSH 모두, Git LFS 포함)가 지원됩니다.

## 커밋이 **세컨더리** 사이트로 복제되는 데 얼마나 오래 걸립니까? {#how-long-does-it-take-to-have-a-commit-replicated-to-a-secondary-site}

모든 복제 작업은 비동기이며 발송을 위해 대기열에 추가됩니다. 따라서 트래픽의 양, 커밋의 크기, 사이트 간의 연결성, 하드웨어 등 많은 요소에 따라 달라집니다.

## SSH 서버가 다른 포트에서 실행되면 어떻게 됩니까? {#what-if-the-ssh-server-runs-at-a-different-port}

전혀 문제없습니다. 우리는 HTTP(s)를 사용하여 **프라이머리** 사이트에서 모든 **세컨더리** 사이트로 리포지토리 변경 사항을 가져옵니다.

## 세컨더리 사이트의 컨테이너 레지스트리를 프라이머리를 미러하도록 만들 수 있습니까? {#can-i-make-a-container-registry-for-a-secondary-site-to-mirror-the-primary}

네, 하지만 우리는 재해 복구 시나리오에 대해서만 이를 지원합니다. [**세컨더리** 사이트의 컨테이너 레지스트리](container_registry.md)를 참조하세요.

## 세컨더리 사이트에 로그인할 수 있습니까? {#can-you-sign-in-to-a-secondary-site}

네, 하지만 세컨더리 사이트는 프라이머리 인스턴스에서 모든 인증 데이터(사용자 계정 및 로그인 포함)를 수신합니다. 이는 인증을 위해 프라이머리로 리디렉션된 후 다시 라우팅됨을 의미합니다.

## 모든 Geo 사이트가 프라이머리와 동일해야 합니까? {#do-all-geo-sites-need-to-be-the-same-as-the-primary}

아니요, Geo 사이트는 다른 참조 아키텍처를 기반으로 할 수 있습니다. 예를 들어 프라이머리 사이트를 3K 참조 아키텍처를 기반으로, 하나의 세컨더리 사이트를 3K 참조 아키텍처를 기반으로, 다른 하나를 1K 참조 아키텍처를 기반으로 할 수 있습니다.

## Geo가 아카이브된 프로젝트를 복제합니까? {#does-geo-replicate-archived-projects}

네, [선택적 동기화](selective_synchronization.md)를 통해 제외되지 않는 한.

## Geo가 개인 프로젝트를 복제합니까? {#does-geo-replicate-personal-projects}

네, [선택적 동기화](selective_synchronization.md)를 통해 제외되지 않는 한.

## 지연된 삭제 프로젝트가 세컨더리 사이트로 복제됩니까? {#are-delayed-deletion-projects-replicated-to-secondary-sites}

네, [지연된 삭제](../../settings/visibility_and_access_controls.md#deletion-protection)에 의해 삭제 예약되었지만 아직 영구 삭제되지 않은 프로젝트는 세컨더리 사이트로 복제됩니다.

## 프라이머리 사이트가 다운되면 세컨더리 사이트는 어떻게 됩니까? {#what-happens-to-my-secondary-sites-with-when-my-primary-site-goes-down}

프라이머리 사이트가 다운되면 [세컨더리가 UI를 통해 액세스할 수 없습니다](../secondary_proxy/_index.md#behavior-of-secondary-sites-when-the-primary-geo-site-is-down). 프라이머리 사이트의 서비스를 복구하거나 세컨더리 사이트에서 승격을 수행하지 않는 한 말입니다.
