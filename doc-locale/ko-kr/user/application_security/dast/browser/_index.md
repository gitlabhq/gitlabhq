---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 브라우저 기반 분석기
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> DAST 버전 4 브라우저 기반 분석기는 GitLab 17.0에서 DAST 버전 5로 대체되었습니다. DAST 버전 5로 마이그레이션하는 방법에 대한 지침은 [마이그레이션 가이드](../browser_based_4_to_5_migration_guide.md)를 참조하세요.

브라우저 기반 DAST는 웹 애플리케이션의 보안 약점(CWE)을 식별하는 데 도움이 됩니다. 웹 애플리케이션을 배포한 후 배포 전에 감지할 수 없는 많은 새로운 유형의 공격에 노출됩니다. 예를 들어 애플리케이션 서버의 잘못된 구성이나 보안 제어에 대한 잘못된 가정이 소스 코드에서 보이지 않을 수 있지만 브라우저 기반 DAST로 감지할 수 있습니다.

DAST(동적 애플리케이션 보안 테스팅)는 배포된 환경에서 애플리케이션의 이와 같은 취약성을 검사합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [DAST - 고급 보안 테스팅](https://www.youtube.com/watch?v=nbeDUoLZJTo)을 참조하세요.

> [!warning]
> DAST 검색을 프로덕션 서버에 대해 실행하지 않습니다. 버튼 클릭이나 양식 제출과 같이 사용자가 수행할 수 있는 모든 기능을 수행할 수 있을 뿐만 아니라 버그를 트리거하여 프로덕션 데이터의 수정 또는 손실로 이어질 수 있습니다. DAST 검색은 테스트 서버에 대해서만 실행합니다.

DAST 브라우저 기반 분석기는 GitLab에서 최신 웹 애플리케이션의 취약성을 스캔하도록 구축되었습니다. 스캔은 단일 페이지 애플리케이션과 같이 JavaScript에 크게 의존하는 애플리케이션 테스트를 최적화하기 위해 브라우저에서 실행됩니다. [DAST가 애플리케이션을 스캔하는 방법](#how-dast-scans-an-application)에 대한 자세한 내용을 참조하세요.

분석기를 CI/CD 파이프라인에 추가하려면 [분석기 활성화](configuration/enabling_the_analyzer.md)를 참조하세요.

## 시작하기 {#getting-started}

DAST를 처음 사용하는 경우 이 가이드에 따라 첫 번째 스캔을 설정하세요.

전제 조건:

- Linux/amd64에서 [러너](../../../../ci/runners/_index.md)와 [`docker` 실행기](https://docs.gitlab.com/runner/executors/docker/).
- 배포된 대상 애플리케이션. [배포 옵션](application_deployment_options.md)을 참조하세요.
- GitLab 러너와 대상 애플리케이션 간의 네트워크 연결.

DAST를 시작하려면:

1. 분석기를 활성화합니다. [DAST CI/CD 작업 생성](configuration/enabling_the_analyzer.md)을 파이프라인에서 스캐너를 실행합니다.
1. 인증을 구성합니다. 애플리케이션에 로그인이 필요한 경우 DAST가 인증된 페이지를 스캔할 수 있도록 [인증 설정](configuration/authentication.md)을 수행합니다.
1. 구성 문제를 해결합니다. 설정 중에 문제가 발생하면 [문제 해결 설명서](troubleshooting.md#setting-up-dast)를 참조하세요.

### 다음 단계 {#next-steps}

첫 번째 스캔을 완료한 후:

- [결과 이해](#understanding-the-results)를 검토하여 스캔 결과를 해석하는 방법을 알아보세요.
- [구성 옵션](configuration/_index.md)을 탐색하여 스캔을 사용자 지정하세요.
- [DAST가 애플리케이션을 스캔하는 방법](#how-dast-scans-an-application)에 대해 자세히 알아보세요.

## 결과 이해 {#understanding-the-results}

파이프라인에서 취약성을 검토할 수 있습니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 취약성을 선택하면 다음을 포함한 세부 정보를 볼 수 있습니다:
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../../vulnerabilities/severities.md).
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 메서드: 취약한 서버 상호 작용 유형을 설정합니다.
   - URL: 취약성의 위치를 표시합니다.
   - 증거: 주어진 취약성의 존재를 증명하기 위한 테스트 사례를 설명합니다.
   - 식별자:  CWE 식별자와 같은 취약성을 분류하는 데 사용되는 참조 목록입니다.

보안 스캔 결과를 다운로드할 수도 있습니다:

- 파이프라인의 **보안** 탭에서 **결과 다운로드**를 선택합니다.

자세한 내용은 [파이프라인 보안 보고서](../../detect/security_scanning_results.md)를 참조하세요.

> [!note]
> 결과는 기능 브랜치에서 생성됩니다. 결과가 기본 브랜치에 병합되면 취약성이 됩니다. 이 구분은 보안 태세를 평가할 때 중요합니다.

## 최적화 {#optimization}

특정 애플리케이션 또는 환경에 대해 DAST를 구성하는 방법에 대한 자세한 내용은 [구성 옵션](configuration/_index.md)을 참조하세요.

## 배포 및 확장 {#roll-out}

단일 작업에 대해 DAST를 구성한 후 다른 작업으로 구성을 확장할 수 있습니다:

- 파이프라인이 각 실행에서 동일한 웹 서버에 배포하도록 구성된 경우 주의하세요. 서버가 업데이트되는 동안 DAST 스캔을 실행하면 부정확하고 비결정적인 결과가 발생합니다.
- 러너를 [항상 끌어오기 정책](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy)을 사용하도록 구성하여 분석기의 최신 버전을 실행합니다.
- 기본적으로 DAST는 파이프라인의 이전 작업에서 정의한 모든 아티팩트를 다운로드합니다. DAST 작업이 `environment_url.txt`에 의존하지 않아 테스트할 URL을 정의하거나 이전 작업에서 생성한 다른 파일을 정의하지 않는 경우 아티팩트를 다운로드하면 안 됩니다. 아티팩트 다운로드를 피하려면 분석기 CI/CD 작업을 확장하여 의존성을 지정하지 않습니다. 예를 들어 DAST 프록시 기반 분석기의 경우 `.gitlab-ci.yml` 파일에 다음을 추가합니다:

  ```yaml
  dast:
    dependencies: []
  ```

## DAST가 애플리케이션을 스캔하는 방법 {#how-dast-scans-an-application}

스캔은 다음 단계를 수행합니다:

1. [인증](configuration/authentication.md)(구성된 경우).
1. 대상 애플리케이션을 [크롤](#crawling-an-application)하여 링크 따라가기, 버튼 클릭, 양식 작성과 같은 사용자 작업을 수행하여 애플리케이션의 표면 영역을 발견합니다.
1. 크롤하는 동안 발견된 HTTP 메시지 및 페이지에서 취약성을 검색하기 위해 [취약성 검색 스캔](#passive-scans)을 수행합니다.
1. 크롤 단계 중에 기록된 HTTP 요청에 페이로드를 삽입하여 취약성을 검색하기 위해 [활성 스캔](#active-scans)을 수행합니다.

### 애플리케이션 크롤 {#crawling-an-application}

"탐색"은 버튼 클릭, 앵커 링크 클릭, 메뉴 항목 열기 또는 양식 작성과 같이 사용자가 페이지에서 수행할 수 있는 작업입니다. "탐색 경로"는 사용자가 애플리케이션을 트래버스하는 방법을 나타내는 탐색 작업의 시퀀스입니다. DAST는 페이지와 콘텐츠를 크롤하고 탐색 경로를 식별하여 애플리케이션의 표면 영역을 발견합니다.

크롤링은 특별히 계측된 Chromium 브라우저에서 대상 애플리케이션 URL을 로드하는 하나의 탐색을 포함하는 탐색 경로로 초기화됩니다. DAST는 모든 탐색 경로가 크롤될 때까지 탐색 경로를 크롤합니다.

탐색 경로를 크롤하려면 DAST는 브라우저 창을 열고 탐색 경로의 모든 탐색 작업을 수행하도록 지시합니다. 브라우저가 최종 작업의 결과 로드를 마치면 DAST는 사용자가 수행할 수 있는 작업에 대해 페이지를 검사하고 각 발견에 대해 새로운 탐색을 만들고 새로운 탐색 경로를 형성하기 위해 탐색 경로에 추가합니다. 예를 들어:

1. DAST는 탐색 경로 `LoadURL[https://example.com]`을 처리합니다.
1. DAST는 `LeftClick[class=menu]` 및 `LeftClick[id=users]` 두 가지 사용자 작업을 찾습니다.
1. DAST는 `LoadURL[https://example.com] -> LeftClick[class=menu]` 및 `LoadURL[https://example.com] -> LeftClick[id=users]` 두 개의 새로운 탐색 경로를 만듭니다.
1. 두 개의 새로운 탐색 경로에서 크롤링이 시작됩니다.

HTML 요소가 모든 페이지에 표시되는 메뉴와 같이 애플리케이션의 여러 위치에 존재하는 것이 일반적입니다. 중복 요소로 인해 크롤러가 동일한 페이지를 다시 크롤하거나 루프에 갇힐 수 있습니다. DAST는 HTML 특성을 기반으로 한 요소 고유성 계산을 사용하여 이전에 크롤한 새로운 탐색 작업을 버립니다.

### 수동 스캔 {#passive-scans}

수동 스캔은 스캔의 크롤 단계 중에 발견된 페이지에서 취약성을 확인합니다. 수동 스캔은 데이터 삭제와 같은 파괴적인 작업을 수행하는 것을 포함하여 일반 사용자와 동일한 방식으로 사이트와 상호 작용하려고 시도합니다. 그러나 수동 스캔은 적대적 행동을 시뮬레이션하지 않습니다. 수동 스캔은 기본적으로 활성화됩니다.

검사는 HTTP 메시지, 쿠키, 저장소 이벤트, 콘솔 이벤트 및 DOM에서 취약성을 검색합니다. 수동 검사의 예에는 노출된 신용카드, 노출된 비밀 토큰, 누락된 콘텐츠 보안 정책 및 신뢰할 수 없는 위치로의 리디렉션 검색이 포함됩니다.

개별 검사에 대한 자세한 내용은 [검사](checks/_index.md)를 참조하세요.

### 활성 스캔 {#active-scans}

활성 스캔은 크롤 단계 중에 기록된 HTTP 요청에 공격 페이로드를 삽입하여 취약성을 확인합니다. 활성 스캔은 적대적 행동을 시뮬레이션하기 때문에 기본적으로 비활성화됩니다.

DAST는 쿼리 값, 헤더 값, 쿠키 값, 양식 게시 및 JSON 문자열 값과 같은 삽입 위치에 대해 각 기록된 HTTP 요청을 분석합니다. 공격 페이로드는 삽입 위치에 삽입되어 새로운 요청을 형성합니다. DAST는 대상 애플리케이션에 요청을 보내고 HTTP 응답을 사용하여 공격 성공을 판단합니다.

활성 스캔은 두 가지 유형의 활성 검사를 실행합니다:

- 일치 응답 공격은 응답 콘텐츠를 분석하여 공격 성공을 판단합니다. 예를 들어, 공격이 시스템 암호 파일을 읽으려고 시도하면 응답 본문에 암호 파일의 증거가 포함될 때 발견이 생성됩니다.
- 타이밍 공격은 응답 시간을 사용하여 공격 성공을 판단합니다. 예를 들어, 공격이 대상 애플리케이션을 슬립하도록 강제하려고 시도하면 애플리케이션이 슬립 시간보다 오래 응답하는 데 걸리면 발견이 생성됩니다. 타이밍 공격은 거짓 긍정을 최소화하기 위해 서로 다른 공격 페이로드로 여러 번 반복됩니다.

간단한 타이밍 공격은 다음과 같이 작동합니다:

1. 크롤 단계는 HTTP 요청 `https://example.com?search=people`을 기록합니다.
1. DAST는 URL을 분석하고 URL 매개 변수 삽입 위치 `https://example.com?search=[INJECT]`을 찾습니다.
1. 활성 검사는 Linux 호스트를 슬립하도록 시도하는 페이로드 `sleep 10`을 정의합니다.
1. DAST는 삽입된 페이로드 `https://example.com?search=sleep%2010`을 사용하여 대상 애플리케이션에 새로운 HTTP 요청을 보냅니다.
1. 대상 애플리케이션은 쿼리 매개 변수 값을 검증 없이 시스템 명령으로 실행하면 취약성이 있으며 예를 들어 `system(params[:search])`
1. DAST는 응답 시간이 10초 이상 걸리면 발견이 생성됩니다.
