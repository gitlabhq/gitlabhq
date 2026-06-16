---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 액세스 토큰 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.2에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/467416).

{{< /history >}}

## 토큰 만료 날짜 분석 {#analyze-token-expiration-dates}

GitLab 16.0에서 [백그라운드 마이그레이션](https://gitlab.com/gitlab-org/gitlab/-/issues/369123)은 모든 만료되지 않은 개인, 프로젝트 및 그룹 액세스 토큰에 해당 토큰이 생성된 후 1년 후로 설정된 만료 날짜를 제공했습니다.

이 마이그레이션의 영향을 받았을 수 있는 토큰을 식별하려면 모든 액세스 토큰을 분석하고 가장 일반적인 상위 10개 만료 날짜를 표시하는 Rake 작업을 실행할 수 있습니다:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:analyze'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="자체 컴파일(소스)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< /tabs >}}

이 작업은 모든 액세스 토큰을 분석하고 만료 날짜별로 그룹화합니다. 왼쪽 열은 만료 날짜를 표시하고, 오른쪽 열은 해당 만료 날짜를 가진 토큰의 개수를 표시합니다. 출력 예시:

```plaintext
======= Personal/Project/Group Access Token Expiration Migration =======
Started at: 2023-06-15 10:20:35 +0000
Finished  : 2023-06-15 10:23:01 +0000
===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
| Expiration Date | Count |
|-----------------|-------|
| 2024-06-15      | 1565353 |
| 2017-12-31      | 2508  |
| 2018-01-01      | 1008  |
| 2016-12-31      | 833   |
| 2017-08-31      | 705   |
| 2017-06-30      | 596   |
| 2018-12-31      | 548   |
| 2017-05-31      | 523   |
| 2017-09-30      | 520   |
| 2017-07-31      | 494   |
========================================================================
```

이 예시에서 150만 개 이상의 액세스 토큰이 2023-06-15에 실행된 마이그레이션의 1년 후인 2024-06-15의 만료 날짜를 가지고 있습니다. 이는 대부분의 이러한 토큰이 마이그레이션에 의해 할당되었음을 시사합니다. 그러나 다른 토큰이 동일한 날짜로 수동으로 생성되었는지 확실하게 알 수 있는 방법은 없습니다.

## 일괄적으로 만료 날짜 업데이트 {#update-expiration-dates-in-bulk}

전제 조건:

다음을 수행해야 합니다:

- 관리자여야 합니다.
- 대화형 터미널이 있어야 합니다.

다음 Rake 작업을 실행하여 토큰의 만료 날짜를 일괄적으로 연장하거나 제거합니다:

1. 도구를 실행합니다:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:edit'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="자체 컴파일(소스)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< /tabs >}}

   도구가 시작되면 [분석 단계](#analyze-token-expiration-dates)의 출력과 만료 날짜 수정에 대한 추가 프롬프트를 표시합니다:

   ```plaintext
   ======= Personal/Project/Group Access Token Expiration Migration =======
   Started at: 2023-06-15 10:20:35 +0000
   Finished  : 2023-06-15 10:23:01 +0000
   ===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
   | Expiration Date | Count |
   |-----------------|-------|
   | 2024-05-14      | 1565353 |
   | 2017-12-31      | 2508  |
   | 2018-01-01      | 1008  |
   | 2016-12-31      | 833   |
   | 2017-08-31      | 705   |
   | 2017-06-30      | 596   |
   | 2018-12-31      | 548   |
   | 2017-05-31      | 523   |
   | 2017-09-30      | 520   |
   | 2017-07-31      | 494   |
   ========================================================================
   What do you want to do? (Press ↑/↓ arrow or 1-3 number to move and Enter to select)
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

### 만료 날짜 연장 {#extend-expiration-dates}

주어진 만료 날짜와 일치하는 모든 토큰의 만료 날짜를 연장하려면:

1. 옵션 1 `Extend expiration date`을 선택합니다:

   ```plaintext
   What do you want to do?
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

1. 도구가 나열된 만료 날짜 중 하나를 선택하도록 요청합니다. 예를 들어:

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   키보드의 화살표 키를 사용하여 날짜를 선택합니다. 중단하려면 아래로 스크롤하여 `--> Abort`을 선택합니다. <kbd>Enter</kbd> 키를 눌러 선택을 확인합니다:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

   날짜를 선택하면 도구가 새 만료 날짜를 입력하도록 요청합니다:

   ```plaintext
   What would you like the new expiration date to be? (2025-05-14) 2024-05-14
   ```

   기본값은 선택한 날짜로부터 1년입니다. <kbd>Enter</kbd> 키를 눌러 기본값을 사용하거나 `YYYY-MM-DD` 형식으로 날짜를 수동으로 입력합니다.

1. 유효한 날짜를 입력한 후 도구가 한 번 더 확인을 요청합니다:

   ```plaintext
   Old expiration date: 2024-05-14
   New expiration date: 2025-05-14
   WARNING: This will now update 1565353 token(s). Are you sure? (y/N)
   ```

   `y`을 입력하면 도구가 선택한 만료 날짜를 가진 모든 토큰의 만료 날짜를 연장합니다.

   `N`을 입력하면 도구가 업데이트 작업을 중단하고 원래 분석 출력으로 돌아갑니다.

### 만료 날짜 제거 {#remove-expiration-dates}

주어진 만료 날짜와 일치하는 모든 토큰의 만료 날짜를 제거하려면:

1. 옵션 2 `Remove expiration date`을 선택합니다:

   ```plaintext
   What do you want to do?
     1. Extend expiration date
   ‣ 2. Remove expiration date
     3. Quit
   ```

1. 도구가 테이블에서 만료 날짜를 선택하도록 요청합니다. 예를 들어:

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   키보드의 화살표 키를 사용하여 날짜를 선택합니다. 중단하려면 아래로 스크롤하여 `--> Abort`을 선택합니다. <kbd>Enter</kbd> 키를 눌러 선택을 확인합니다:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

1. 날짜를 선택한 후 도구가 선택을 확인하도록 요청합니다:

   ```plaintext
   WARNING: This will remove the expiration for tokens that expire on 2024-05-14.
   This will affect 1565353 tokens. Are you sure? (y/N)
   ```

   `y`을 입력하면 도구가 선택한 만료 날짜를 가진 모든 토큰의 만료 날짜를 제거합니다.

   `N`을 입력하면 도구가 업데이트 작업을 중단하고 첫 번째 메뉴로 돌아갑니다.

## CI/CD ID 토큰에 대한 사용자 정의 발급자 URL 구성 검증 {#validate-custom-issuer-url-configuration-for-cicd-id-tokens}

[OpenID Connect in AWS를 사용하여 임시 자격 증명을 검색](../../../ci/cloud_services/aws/_index.md#configure-a-non-public-gitlab-instance)하도록 공개되지 않은 GitLab 인스턴스를 구성하는 경우 `ci:validate_id_token_configuration` Rake 작업을 사용하여 토큰 구성을 검증합니다:

```shell
bundle exec rake ci:validate_id_token_configuration
```
