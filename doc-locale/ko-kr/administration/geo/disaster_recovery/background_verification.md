---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: 자동 백그라운드 검증
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

자동 백그라운드 검증은 전송된 데이터가 계산된 체크섬과 일치하는지 확인합니다. **프라이머리** 사이트의 데이터 체크섬이 **세컨더리** 사이트의 데이터 체크섬과 일치하면 데이터가 성공적으로 전송됩니다. 계획된 장애 조치 후 손상의 정도에 따라 손상된 데이터가 **lost**될 수 있습니다.

**프라이머리** 사이트에서 검증이 실패하면 Geo가 손상된 개체를 복제하고 있음을 나타냅니다. 백업에서 복원하거나 **프라이머리** 사이트에서 제거하여 문제를 해결할 수 있습니다.

**프라이머리** 사이트에서는 검증이 성공하지만 **세컨더리** 사이트에서 실패하면 복제 프로세스 중에 개체가 손상되었음을 나타냅니다. Geo는 백오프 기간이 있는 재동기화를 위해 리포지토리를 표시하여 검증 실패를 적극적으로 수정하려고 시도합니다. 이러한 실패에 대해 검증을 재설정하려면 [다음 지침](background_verification.md#reset-verification-for-projects-where-verification-has-failed)을 따르세요.

검증이 복제 작업보다 크게 지연되면 계획된 장애 조치를 예약하기 전에 사이트에 더 많은 시간을 주는 것을 고려하세요.

## 리포지토리 검증 {#repository-verification}

전제 조건:

- 운영자 액세스 권한.

**프라이머리** 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 해당 사이트의 **검증 정보** 탭을 확장하여 리포지토리 및 위키에 대한 자동 체크섬 상태를 봅니다. 성공은 초록색으로, 대기 중인 작업은 회색으로, 실패는 빨간색으로 표시됩니다.

   ![건강한 프라이머리 Geo 인스턴스의 개요를 보여주는 검증 정보 탭](img/verification_status_primary_v14_0.png)

**세컨더리** 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 해당 사이트의 **검증 정보** 탭을 확장하여 리포지토리 및 위키에 대한 자동 체크섬 상태를 봅니다. 성공은 초록색으로, 대기 중인 작업은 회색으로, 실패는 빨간색으로 표시됩니다.

   ![건강한 세컨더리 Geo 인스턴스의 개요를 보여주는 검증 정보 탭](img/verification_status_secondary_v14_0.png)

## 체크섬을 사용하여 Geo 사이트 비교 {#using-checksums-to-compare-geo-sites}

Geo **세컨더리** 사이트의 건강 상태를 확인하기 위해 Git 참조 및 해당 값 목록에 대한 체크섬을 사용합니다. 체크섬에는 `HEAD`, `heads`, `tags`, `notes` 및 GitLab 특정 참조가 포함되어 진정한 일관성을 보장합니다. 두 사이트의 체크섬이 동일하면 동일한 참조를 보유하고 있습니다. 모든 사이트가 동기화되어 있는지 확인하기 위해 모든 업데이트 후 모든 사이트에 대한 체크섬을 계산합니다.

## 리포지토리 재검증 {#repository-re-verification}

버그나 일시적 인프라 장애로 인해 Git 리포지토리가 검증을 위해 표시되지 않고 예기치 않게 변경될 수 있습니다. Geo는 데이터의 무결성을 보장하기 위해 리포지토리를 지속적으로 재검증합니다. 기본 및 권장 재검증 간격은 7일이지만 1일 정도의 간격을 설정할 수 있습니다. 더 짧은 간격은 위험을 줄이지만 부하를 증가시키며 그 반대도 마찬가지입니다.

**프라이머리** 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. **편집** 사이트의 **프라이머리**을 선택하여 최소 재검증 간격을 사용자 지정합니다:

   ![Geo 노드의 구성 속성을 보여주는 창](img/reverification-interval_v11_6.png)

## 검증이 실패한 프로젝트에 대한 검증 재설정 {#reset-verification-for-projects-where-verification-has-failed}

Geo는 백오프 기간이 있는 재동기화를 위해 리포지토리를 표시하여 검증 실패를 적극적으로 수정하려고 시도합니다. [UI 또는 Rails 콘솔을 통해 개별 구성 요소를 수동으로 다시 동기화하고 재검증](../replication/troubleshooting/synchronization_verification.md#resync-and-reverify-individual-components)할 수도 있습니다.

## 체크섬 불일치로 인한 차이점 조정 {#reconcile-differences-with-checksum-mismatches}

{{< history >}}

- **Storage name** 및 **Relative path** 필드가 GitLab 16.3에서 **Gitaly storage name** 및 **Gitaly relative path**에서 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416)되었습니다.

{{< /history >}}

**프라이머리** 및 **세컨더리** 사이트의 체크섬 검증 불일치가 있는 경우 원인이 명확하지 않을 수 있습니다. 체크섬 불일치의 원인을 찾으려면:

1. **프라이머리** 사이트에서:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다.
   1. 체크섬 차이를 확인하려는 프로젝트를 찾아 해당 이름을 선택합니다.
   1. 프로젝트 관리 페이지에서 **Storage name** 및 **Relative path** 필드의 값을 가져옵니다.

1. **Gitaly node on the primary** 및 **Gitaly node on the secondary** 사이트에서 프로젝트의 리포지토리 디렉터리로 이동합니다. Gitaly Cluster(Praefect)를 사용하는 경우 이러한 명령을 실행하기 전에 [건강한 상태인지 확인](../../gitaly/praefect/troubleshooting.md#check-cluster-health)합니다.

   기본 경로는 `/var/opt/gitlab/git-data/repositories`입니다. 리포지토리 스토리지가 사용자 지정된 경우 서버의 디렉터리 레이아웃을 확인하여 확인합니다:

   ```shell
   cd /var/opt/gitlab/git-data/repositories
   ```

   1. **프라이머리** 사이트에서 다음 명령을 실행하여 출력을 파일로 리다이렉트합니다:

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > primary-site-refs
      ```

   1. **세컨더리** 사이트에서 다음 명령을 실행하여 출력을 파일로 리다이렉트합니다:

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > secondary-site-refs
      ```

   1. 이전 단계의 파일을 같은 시스템에 복사하고 내용 간에 차이점을 확인합니다:

      ```shell
      diff primary-site-refs secondary-site-refs
      ```

## 현재 제한 사항 {#current-limitations}

지원되는 복제 및 검증 방법에 대한 자세한 내용은 [지원되는 Geo 데이터 유형](../replication/datatypes.md)을 참조하세요.
