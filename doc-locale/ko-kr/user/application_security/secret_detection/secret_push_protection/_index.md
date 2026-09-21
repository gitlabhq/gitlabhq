---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시크릿 푸시 보호
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/11439)되었으며 GitLab Dedicated 고객을 위한 [실험](../../../../policy/development_stages_support.md)입니다.
- [변경](https://gitlab.com/groups/gitlab-org/-/epics/12729)되어 GitLab 17.1에서 GitLab.com에서 사용 가능해졌습니다.
- GitLab 17.2에서 `pre_receive_secret_detection_beta_release` 및 `pre_receive_secret_detection_push_check`라는 [기능 플래그](../../../../administration/feature_flags/_index.md)로 [GitLab Self-Managed에 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156907)되었습니다.
- 기능 플래그 `pre_receive_secret_detection_beta_release`이 GitLab 17.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/472418)되었습니다.
- GitLab 17.5에서 [일반 공개](https://gitlab.com/groups/gitlab-org/-/epics/13107)되었습니다.
- GitLab 17.7에서 `pre_receive_secret_detection_push_check` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/472419)되었습니다.

{{< /history >}}

시크릿 푸시 보호는 키, API 토큰과 같은 시크릿이 GitLab으로 푸시되는 것을 차단합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 확인하려면 [시크릿 푸시 보호 시작하기](https://www.youtube.com/playlist?list=PL05JrBw4t0KoADm-g2vxfyR0m6QLphTv-) 재생 목록을 참고하세요.

파이프라인 시크릿 탐지를 시크릿 푸시 보호와 함께 사용하여 보안을 더욱 강화하세요.

## 시크릿 푸시 보호 워크플로 {#secret-push-protection-workflow}

시크릿 푸시 보호는 수신 이전 후크에서 발생합니다. GitLab으로 변경 사항을 푸시하면 푸시 보호가 각 파일 또는 커밋에서 시크릿을 검사합니다. 기본적으로 시크릿이 탐지되면 푸시를 차단합니다.

<!-- To edit the diagram, use either Draw.io or the VS Code extension "Draw.io Integration" -->
![시크릿 보호가 푸시를 차단하는 방법을 보여주는 순서도](img/spp_workflow_v17_9.drawio.svg)

푸시가 차단되면 GitLab에서 다음을 포함하는 메시지가 표시됩니다.

- 시크릿을 포함하는 커밋 ID입니다.
- 시크릿을 포함하는 파일 이름과 라인입니다.
- 시크릿의 유형입니다.

예를 들어, Git CLI를 사용하여 푸시가 차단되었을 때 반환되는 메시지의 추출본은 다음과 같습니다. GitLab Web IDE를 포함한 다른 클라이언트를 사용할 때는 메시지의 형식이 다르지만 내용은 동일합니다.

```plain
remote: PUSH BLOCKED: Secrets detected in code changes
remote: Secret push protection found the following secrets in commit: 37e54de5e78c31d9e3c3821fd15f7069e3d375b6
remote:
remote: -- test.txt:2 GitLab Personal Access Token
remote:
remote: To push your changes you must remove the identified secrets.
```

시크릿 푸시 보호가 커밋에서 시크릿을 탐지하지 못하면 메시지가 표시되지 않습니다.

## 탐지된 시크릿 {#detected-secrets}

시크릿 푸시 보호는 파일 또는 커밋에서 특정 패턴을 검사합니다. 각 패턴은 특정 유형의 시크릿과 일치합니다. 시크릿 푸시 보호에서 탐지한 시크릿을 확인하려면 [탐지된 시크릿](../detected_secrets.md)을 참고하세요. 커밋을 푸시할 때 지연을 최소화하고 잘못된 알림 수를 줄이기 위해 시크릿 푸시 보호에 대해 높은 신뢰도 패턴만 선택되었습니다. 예를 들어 사용자 지정 접두사를 사용하는 개인 액세스 토큰은 시크릿 푸시 보호에서 탐지되지 않습니다. 시크릿 푸시 보호에 의한 탐지에서 선택한 시크릿을 [제외](../exclusions.md)할 수 있습니다.

## 시작하기 {#getting-started}

GitLab Dedicated 및 GitLab Self-Managed 인스턴스에서는 다음을 수행해야 합니다.

1. 전체 인스턴스에서 시크릿 푸시 보호를 허용합니다.
1. 시크릿 푸시 보호를 사용으로 설정합니다. 다음 중 하나를 수행할 수 있습니다.
   - 특정 프로젝트에서 시크릿 푸시 보호를 사용으로 설정합니다.
   - API를 사용하여 그룹의 모든 프로젝트에 시크릿 푸시 보호를 사용으로 설정합니다.

### GitLab 인스턴스에서 시크릿 푸시 보호의 사용을 허용 {#allow-the-use-of-secret-push-protection-in-your-gitlab-instance}

GitLab Dedicated 및 GitLab Self-Managed 인스턴스에서는 프로젝트에 시크릿 푸시 보호를 사용으로 설정하기 전에 먼저 허용해야 합니다.

사전 요구 사항:

- GitLab 인스턴스의 관리자여야 합니다.

GitLab 인스턴스에서 시크릿 푸시 보호의 사용을 허용하려면 다음을 수행합니다.

1. 관리자로 GitLab 인스턴스에 로그인합니다.
1. 오른쪽 위 모서리에서 **관리자**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **보안 및 규정 준수**를 선택합니다.
1. **시크릿 탐지** 아래에서 **시크릿 푸시 보호 허용**을 선택하거나 지웁니다.

인스턴스에 시크릿 푸시 보호가 허용됩니다. 이 기능을 사용하려면 프로젝트마다 사용으로 설정해야 합니다.

### 프로젝트에서 시크릿 푸시 보호 사용 {#enable-secret-push-protection-in-a-project}

사전 요구 사항:

- 프로젝트의 보안 관리자, 유지 관리자 또는 소유자 역할이 있어야 합니다.
- GitLab Dedicated 및 GitLab Self-Managed에서는 인스턴스에서 시크릿 푸시 보호를 허용해야 합니다.

프로젝트에서 시크릿 푸시 보호를 사용으로 설정하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **시크릿 푸시 보호** 토글을 켭니다.

또한 [API를 사용하여](../../../../api/group_security_settings.md#update-group-security-settings) 그룹의 모든 프로젝트에 대해 시크릿 푸시 보호를 사용으로 설정할 수 있습니다.

## 범위 {#coverage}

{{< history >}}

- GitLab 17.11에서 차이점만 검사하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185882)되었습니다.

{{< /history >}}

시크릿 푸시 보호는 다음과 같은 경우 시크릿을 차단하지 않습니다:

- 커밋을 푸시할 때 시크릿 푸시 보호 건너뛰기 옵션을 사용합니다.
- 시크릿이 시크릿 푸시 보호에서 제외되어 있습니다.
- 시크릿이 [제외](../exclusions.md)로 정의된 경로에 있습니다.

시크릿 푸시 보호는 다음과 같은 경우 커밋의 파일을 검사하지 않습니다.

- 파일이 바이너리 파일입니다.
- 파일 또는 diff 패치가 1 MiB보다 큽니다.
- 파일이 이름 변경, 삭제 또는 내용 변경 없이 이동되었습니다.
- 파일의 내용이 소스 코드의 다른 파일의 내용과 동일합니다.
- 파일이 리포지토리를 만든 초기 푸시에 포함되어 있습니다.
- 푸시에 총 350,000줄보다 많은 변경 줄이 포함되어 있습니다.

### 차이점 검사 {#diff-scanning}

{{< history >}}

- GitLab 17.5에서 `spp_scan_diffs`라는 [기능 플래그](../../../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/469161)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 17.6에서 [GitLab.com에 사용](https://gitlab.com/gitlab-org/gitlab/-/issues/480092)으로 설정되었습니다.
- GitLab 17.10에서 Web IDE 푸시 지원이 [기능 플래그](../../../../administration/feature_flags/_index.md) `secret_checks_for_web_requests`와 함께 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/491282)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 17.11에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/525627)되었습니다. `spp_scan_diffs` 기능 플래그가 제거되었습니다.
- GitLab 17.11에서 `secret_checks_for_web_requests` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/525629)되었습니다.

{{< /history >}}

시크릿 푸시 보호는 HTTP(S) 및 SSH를 통해 푸시된 커밋의 diff만 검사합니다. 시크릿이 이미 파일에 있고 변경 사항의 일부가 아니면 탐지되지 않습니다.

## 감사 이벤트 {#audit-events}

{{< history >}}

- GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/604787)되었습니다.

{{< /history >}}

[감사 이벤트](../../../compliance/audit_event_types.md#secret-detection)는 다음과 같은 경우에 기록됩니다.

- 푸시에 [너무 많은 변경된 경로](#push-size-threshold)가 포함되어 있기 때문에 시크릿 푸시 보호를 건너뜁니다.
- 푸시가 [너무 많은 줄을 변경](#push-size-threshold)하기 때문에 시크릿 푸시 보호를 건너뜁니다.
- 시크릿 푸시 보호 검사 시간 초과가 발생하고 GitLab이 푸시를 수락합니다.
- 시크릿 푸시 보호에 규칙 집합 구문 분석 또는 컴파일 오류가 발생합니다.
- 검사에 잘못된 입력을 받았기 때문에 시크릿 푸시 보호를 건너뜁니다.
- 시크릿 푸시 보호에 예기치 않은 검사 오류가 발생합니다.

## 푸시 크기 임계값 {#push-size-threshold}

푸시가 3,150개 이상의 경로 또는 350,000줄 이상을 변경하면 시크릿 푸시 보호를 건너뜁니다. 임계값은 시크릿 푸시 보호에서 검사하는 파일에만 적용됩니다([제외](../exclusions.md)에 정의된 경로를 제외한 후에). 이러한 임계값은 큰 변경 집합을 푸시할 때 푸시 시간 초과를 방지합니다.

## 결과를 이해하기 {#understanding-the-results}

시크릿 푸시 보호에서는 다양한 범주의 시크릿을 식별할 수 있습니다.

- API 키 및 토큰: 서비스 특정 인증 자격 증명
- 데이터베이스 연결 문자열: 포함된 자격 증명이 있는 URL
- 개인 키: 인증 또는 암호화를 위한 암호화 키
- 일반 고엔트로피 문자열: 무작위로 생성된 시크릿으로 보이는 패턴

푸시가 차단되면 시크릿 푸시 보호는 탐지된 시크릿을 찾아 해결할 수 있도록 자세한 정보를 제공합니다.

- 커밋 ID: 시크릿을 포함하는 특정 커밋입니다. Git 기록의 변경 사항을 추적하는 데 유용합니다.
- 파일 경로 및 라인 번호: 빠른 탐색을 위한 탐지된 패턴의 정확한 위치입니다.
- 시크릿 유형: 탐지된 패턴의 분류입니다. 예를 들어 `GitLab Personal Access Token` 또는 `AWS Access Key`입니다.

### 일반적인 탐지 범주 {#common-detection-categories}

모든 탐지에 대해 즉시 조치가 필요한 것은 아닙니다. 결과를 평가할 때 다음을 고려하세요:

- 정탐: 회전되고 제거해야 하는 정당한 시크릿입니다. 예를 들어 다음과 같습니다.
  - 유효한 API 키 또는 토큰
  - 프로덕션 데이터베이스 자격 증명
  - 개인 암호화 키
  - 무단 액세스를 허용할 수 있는 모든 자격 증명
- 오탐: 실제 시크릿이 아닌 탐지된 패턴입니다. 예를 들어 다음과 같습니다.
  - 시크릿과 유사하지만 실제 가치가 없는 테스트 데이터
  - 구성 템플릿의 자리 표시자 값
  - 설명서의 예제 자격 증명
  - 시크릿 패턴과 일치하는 해시 값 또는 체크섬

조직의 일반적인 오탐 패턴을 문서화하여 향후 평가를 간소화하세요.

## 최적화 {#optimization}

시크릿 푸시 보호를 광범위하게 배포하기 전에 구성을 최적화하여 오탐을 줄이고 특정 환경에 대한 정확성을 향상합니다.

### 오탐 줄이기 {#reduce-false-positives}

오탐은 개발자 생산성에 심각한 영향을 미치고 보안 피로로 이어질 수 있습니다.

오탐을 줄이려면 다음과 같이 합니다.

- [제외 구성](../exclusions.md)을 전략적으로 수행합니다.
  - 테스트 디렉터리, 설명서 및 타사 종속성에 대한 경로 기반 제외를 만듭니다.
  - 특히 코드베이스에 대해 알려진 오탐 패턴에 대한 패턴 기반 제외를 사용합니다.
  - 제외 규칙을 문서화하고 정기적으로 검토합니다.
- 제외 규칙과 일치해야 하지만 [기본 규칙 집합](../detected_secrets.md)과는 일치하지 않는 자리 표시자 값 및 테스트 자격 증명에 대한 표준을 만듭니다.
- 오탐 비율을 모니터링하고 이에 따라 제외를 조정합니다.

### 성능 최적화 {#optimize-performance}

큰 리포지토리 또는 빈번한 푸시는 성능에 영향을 미칠 수 있습니다.

시크릿 푸시 보호의 성능을 최적화하려면 다음을 수행합니다.

- 푸시 시간을 모니터링하고 배포 전에 기준선 메트릭을 설정합니다.
- 큰 바이너리 자산이 있는 리포지토리에 대해 파일 크기 제한을 고려하세요.
- 시크릿을 포함할 가능성이 낮은 디렉터리에 대해 [제외를 구현](../exclusions.md#add-an-exclusion)합니다.

### 기존 워크플로와의 통합 {#integration-with-existing-workflows}

시크릿 푸시 보호가 기존 개발 관행을 보완하는지 확인합니다.

- 파이프라인 시크릿 탐지 및 시크릿 푸시 보호를 구성하여 심층 방어가 있는지 확인합니다.
- 시크릿 푸시 보호 절차를 포함하도록 개발자 설명서를 업데이트합니다.
- 보안 교육과 정렬하여 개발자에게 보안 코딩 관행을 교육하여 유출되는 시크릿을 최소화합니다.

## 롤아웃 {#roll-out}

시크릿 푸시 보호를 규모에 맞게 배포하려면 신중한 계획과 단계적 구현이 필요합니다.

1. 기능을 테스트하고 개발자 워크플로에 미치는 영향을 파악하기 위해 활발한 개발이 진행되는 비중요 프로젝트 2-3개를 선택합니다.
1. 선택된 테스트 프로젝트에 시크릿 푸시 보호를 활성화하고 개발자 피드백을 모니터링합니다.
1. 차단된 푸시 처리 프로세스를 문서화하고 개발 팀을 새로운 워크플로에 대해 교육합니다.
1. 파일럿 단계 동안 탐지된 시크릿 수, 오탐 비율 및 개발자 경험 피드백을 추적합니다.

더 광범위한 배포 전에 충분한 데이터를 수집하고 필요한 워크플로 조정을 식별하기 위해 파일럿 단계를 2-4주 동안 실행해야 합니다.

파일럿을 완료한 후 확대된 롤아웃을 위해 다음 단계를 고려하세요:

1. 초기 채택자(3-6주)
   - 활성 프로젝트의 10-20%에서 사용으로 설정되어 보안에 민감한 리포지토리를 우선시합니다.
   - 강력한 보안 인식과 지원이 있는 팀에 집중합니다.
   - 성능 영향 및 개발자 경험을 모니터링합니다.
   - 실제 사용을 기반으로 프로세스를 개선합니다.
1. 광범위한 배포(7-12주)
   - 남은 프로젝트 전체에서 배치 단위로 점진적으로 사용으로 설정합니다.
   - 개발 팀에 지속적인 지원 및 교육을 제공합니다.
   - 시스템 성능을 모니터링하고 필요한 경우 인프라를 확장합니다.
   - 사용 패턴을 기반으로 제외 규칙 최적화를 계속합니다.
1. 전체 범위(13-16주)
   - 남은 모든 프로젝트에서 시크릿 푸시 보호를 사용으로 설정합니다.
   - 지속적인 유지 관리 및 검토 프로세스를 설정합니다.
   - 제외 규칙 및 탐지된 패턴의 정기적인 감사를 구현합니다.

## 차단된 푸시 해결 {#resolve-a-blocked-push}

시크릿 푸시 보호로 푸시가 차단되면 다음 중 하나를 수행할 수 있습니다.

- [시크릿 제거](../remove_secrets_tutorial.md)합니다.
- 시크릿 푸시 보호를 건너뜁니다.

### 시크릿 푸시 보호 건너뛰기 {#skip-secret-push-protection}

경우에 따라 시크릿 푸시 보호를 건너뛰어야 할 수도 있습니다. 예를 들어 개발자가 테스트를 위해 자리 표시자 시크릿을 커밋해야 하거나 사용자가 Git 작업 시간 초과로 인해 시크릿 푸시 보호를 건너뛰어야 할 수 있습니다.

시크릿 푸시 보호를 건너뛰면 감사 이벤트가 기록됩니다. 감사 이벤트 세부 정보에는:

- 사용한 건너뛰기 방법입니다.
- GitLab 계정 이름입니다.
- 시크릿 푸시 보호를 건너뛴 날짜 및 시간입니다.
- 시크릿을 푸시한 프로젝트의 이름입니다.
- 대상 브랜치입니다. (GitLab 17.4에서 도입됨)
- 시크릿 푸시 보호를 건너뛴 커밋입니다. (GitLab 17.9에서 도입됨)

파이프라인 시크릿 탐지가 사용으로 설정되면 리포지토리로 푸시된 후 모든 커밋의 내용을 검사합니다.

푸시의 모든 커밋에 대해 시크릿 푸시 보호를 건너뛰려면 다음 중 하나를 수행합니다.

- Git CLI 클라이언트를 사용하는 경우 Git에 시크릿 푸시 보호를 건너뛰도록 명령합니다.
- 다른 클라이언트를 사용하는 경우 `[skip secret push protection]`을 커밋 메시지 중 하나에 추가합니다.

#### Git CLI 클라이언트의 경우 {#for-the-git-cli-client}

명령줄에서 시크릿 푸시 보호를 건너뛰려면 다음을 수행합니다.

- `secret_push_protection.skip_all` 푸시 옵션을 사용합니다.

  예를 들어 여러 푸시 중 하나에 시크릿이 포함되기 때문에 여러 커밋을 푸시하는 것이 차단됩니다. 시크릿 푸시 보호를 건너뛰려면 푸시 옵션을 Git 명령에 추가합니다.

  ```shell
  git push -o secret_push_protection.skip_all
  ```

#### 모든 Git 클라이언트의 경우 {#for-any-git-client}

시크릿 푸시 보호를 건너뛰려면 다음을 수행합니다.

- `[skip secret push protection]`을 커밋 메시지 중 하나에 기존 라인이나 새 라인에 추가하고 커밋을 푸시합니다.

  예를 들어 GitLab Web IDE를 사용하고 있으며 그 중 하나에 시크릿이 포함되기 때문에 여러 커밋을 푸시하는 것이 차단됩니다. 시크릿 푸시 보호를 건너뛰려면 최신 커밋 메시지를 편집하고 `[skip secret push protection]`을 추가한 다음 커밋을 푸시합니다.

## 문제 해결 {#troubleshooting}

시크릿 푸시 보호를 사용할 때 다음과 같은 상황이 발생할 수 있습니다.

### 푸시가 예기치 않게 차단됨 {#push-blocked-unexpectedly}

GitLab 17.11 이전에는 시크릿 푸시 보호에서 모든 수정된 파일의 내용을 검사했습니다. 시크릿이 diff의 일부가 아닌 경우에도 수정된 파일에 시크릿이 포함되어 있으면 푸시가 예상치 않게 차단될 수 있습니다.

GitLab 17.10 이전에는 `spp_scan_diffs` 기능 플래그를 사용으로 설정하여 새로 커밋한 변경 사항만 검사되도록 합니다. Web IDE 변경 사항을 시크릿이 포함된 파일로 푸시하려면 추가로 `secret_checks_for_web_requests` 기능 플래그를 사용으로 설정해야 합니다.

### 검사되지 않은 파일 {#file-was-not-scanned}

일부 파일은 검사에서 제외됩니다. 자세한 내용은 [범위](#coverage)를 참고하세요.
