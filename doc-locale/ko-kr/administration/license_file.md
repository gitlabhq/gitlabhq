---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Enterprise Edition 활성화
description: 라이선스 파일이나 키를 사용하여 GitLab Enterprise Edition을 활성화합니다.
---

GitLab에서 라이선스 파일을 받은 경우(예: 평가판), 인스턴스에 업로드하거나 설치 중에 추가할 수 있습니다. 라이선스 파일은 `.gitlab-license` 확장자를 가진 base64 인코딩 ASCII 텍스트 파일입니다.

GitLab 인스턴스에 처음 로그인하면 **라이선스 추가** 페이지 링크가 포함된 메모가 표시되어야 합니다.

그 외에는 운영자 영역에서 라이선스를 추가합니다.

## 운영자 영역에서 라이선스 추가 {#add-license-in-the-admin-area}

1. GitLab에 관리자로 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **라이선스 추가** 영역에서 파일을 업로드하거나 키를 입력하여 라이선스를 추가합니다.
1. **Terms of Service** 체크박스를 선택합니다.
1. **라이선스 추가**를 선택합니다.

## 설치 중 구독 활성화 {#activate-subscription-during-installation}

{{< history >}}

- [GitLab 16.0에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114572).

{{< /history >}}

설치 중에 구독을 활성화하려면 활성화 코드로 `GITLAB_ACTIVATION_CODE` 환경 변수를 설정합니다:

```shell
export GITLAB_ACTIVATION_CODE=your_activation_code
```

## 설치 중 라이선스 파일 추가 {#add-license-file-during-installation}

라이선스가 있으면 GitLab을 설치할 때도 가져올 수 있습니다.

- 자체 컴파일 설치의 경우:
  - `Gitlab.gitlab-license` 파일을 `config/` 디렉토리에 배치합니다.
  - 라이선스의 사용자 지정 위치와 파일 이름을 지정하려면 `GITLAB_LICENSE_FILE` 환경 변수를 파일 경로로 설정합니다:

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- Linux 패키지 설치의 경우:
  - `Gitlab.gitlab-license` 파일을 `/etc/gitlab/` 디렉토리에 배치합니다.
  - 라이선스의 사용자 지정 위치와 파일 이름을 지정하려면 `gitlab.rb`에 이 항목을 추가합니다:

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

- Helm Charts 설치의 경우 [`global.gitlab.license` 구성 키](https://docs.gitlab.com/charts/installation/command-line-options/#basic-configuration)를 사용합니다.

> [!warning]
> 이러한 방법은 설치 시에만 라이선스를 추가합니다. 라이선스를 갱신하거나 업그레이드하려면 웹 사용자 인터페이스의 **운영자** 영역에서 라이선스를 추가합니다.

## 라이선스 사용 데이터 제출 {#submit-license-usage-data}

오프라인 환경에서 라이선스 파일이나 키를 사용하여 인스턴스를 활성화하는 경우, 향후 구매 및 갱신을 간편하게 하기 위해 매월 라이선스 사용 데이터를 제출하도록 권장합니다. 데이터를 제출하려면 [라이선스 사용 내용을 내보내고](license_usage.md#export-license-usage) 갱신 서비스인 `renewals-service@customers.gitlab.com`로 이메일로 보냅니다. **You must not open the license usage file before you send it**. 그렇지 않으면 사용된 프로그램에서 파일의 내용이 조작될 수 있으며(예: 타임스탬프가 다른 형식으로 변환될 수 있음), 파일을 처리할 때 오류가 발생할 수 있습니다.

구독 시작 날짜 이후 매월 데이터를 제출하지 않으면 구독과 연관된 주소로 이메일이 전송되고 데이터 제출을 알리는 배너가 표시됩니다. 배너는 **운영자** 영역의 **대시보드** 및 **구독** 페이지에 표시되며, 사용 파일이 다운로드된 후 닫을 수 있습니다. 라이선스 사용 데이터를 제출한 후 다음 달까지만 닫을 수 있습니다.

## 라이선스 만료 시 {#what-happens-when-your-license-expires}

라이선스 만료 15일 전에 예정된 만료 날짜가 포함된 알림 배너가 GitLab 관리자에게 표시됩니다.

라이선스는 만료 날짜 시작, 서버 시간 00:00에 만료됩니다.

라이선스가 만료되면 GitLab은 Git 푸시 및 이슈 생성과 같은 기능을 잠급니다. 인스턴스는 읽기 전용이 되고 모든 관리자에게 만료 메시지가 표시됩니다.

예를 들어, 라이선스의 시작 날짜가 2024년 1월 1일이고 종료 날짜가 2025년 1월 1일인 경우:

- 서버 시간 2024년 12월 31일 오후 11:59:59에 만료됩니다.
- 서버 시간 2025년 1월 1일 오전 12:00:00부터 만료된 것으로 간주됩니다.

읽기 전용 상태를 제거하고 기능을 다시 시작하려면 [구독을 갱신합니다](../subscriptions/manage_subscription.md#renew-manually).

라이선스가 30일 이상 만료된 경우, 기능을 다시 시작하려면 [새로운 구독](../subscriptions/manage_subscription.md)을 구매해야 합니다.

Free 기능으로 돌아가려면 [만료된 모든 라이선스를 삭제합니다](#remove-a-license).

## 라이선스 제거 {#remove-a-license}

GitLab Self-Managed 인스턴스에서 라이선스를 제거하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.
1. **라이선스 제거**를 선택합니다.

이러한 단계를 반복하여 과거에 적용된 라이선스를 포함한 모든 라이선스를 제거합니다.

## 라이선스 세부 정보 및 기록 보기 {#view-license-details-and-history}

라이선스 세부 정보를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.

여러 라이선스를 추가하고 볼 수 있지만, 현재 날짜 범위의 최신 라이선스만 활성 라이선스입니다.

향후 날짜의 라이선스를 추가하면 해당 날짜가 될 때까지 적용되지 않습니다. **Subscription history** 테이블에서 모든 활성 구독을 볼 수 있습니다.

라이선스 사용 정보를 CSV 파일로 [내보낼](../subscriptions/manage_subscription.md) 수도 있습니다.

## Rails 콘솔에서 라이선스 명령 {#license-commands-in-the-rails-console}

다음 명령은 [Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 실행할 수 있습니다.

> [!warning]
> 데이터를 직접 변경하는 모든 명령은 올바르게 실행되지 않거나 올바른 조건에서 실행되지 않으면 해로울 수 있습니다. 인스턴스를 복원할 준비가 된 백업으로 테스트 환경에서 실행하도록 강력히 권장합니다.

### 현재 라이선스 정보 확인 {#see-current-license-information}

```ruby
# License information (name, company, email address)
License.current.licensee

# Plan:
License.current.plan

# Uploaded:
License.current.created_at

# Started:
License.current.starts_at

# Expires at:
License.current.expires_at

# Is this a trial license?
License.current.trial?

# License ID for lookup on CustomersDot
License.current.license_id

# License data in Base64-encoded ASCII format
License.current.data

# Confirm the current billable seat count excluding guest users. This is useful for customers who use an Ultimate subscription tier where Guest seats are not counted.
User.active.without_bots.excluding_guests_and_requests.count

```

#### 향후 시작하는 라이선스와의 상호 작용 {#interaction-with-licenses-that-start-in-the-future}

```ruby
# Future license data follows the same format as current license data it just uses a different modifier for the License prefix
License.future_dated
```

### 인스턴스에서 프로젝트 기능을 사용할 수 있는지 확인 {#check-if-a-project-feature-is-available-on-the-instance}

[`features.rb`에 나열된 기능](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

#### 프로젝트에서 프로젝트 기능을 사용할 수 있는지 확인 {#check-if-a-project-feature-is-available-in-a-project}

[`features.rb`에 나열된 기능](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### 콘솔을 통해 라이선스 추가 {#add-a-license-through-the-console}

#### `key` 변수 사용 {#using-a-key-variable}

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

#### 라이선스 파일 사용 {#using-a-license-file}

```ruby
license_file = File.open("/tmp/Gitlab.license")

key = license_file.read.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

이 스니펫을 파일에 저장하고 [Rails Runner를 사용하여](operations/rails_console.md#using-the-rails-runner) 실행하면 라이선스를 셸 자동화 스크립트를 통해 적용할 수 있습니다.

이는 [만료된 라이선스 및 여러 LDAP 서버](auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers)라는 알려진 엣지 케이스에서 필요합니다.

### 라이선스 제거 {#remove-licenses}

[라이선스 기록 테이블](license_file.md#view-license-details-and-history)을 정리하려면:

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## 문제 해결 {#troubleshooting}

### 운영자 영역의 구독 영역 없음 {#no-subscription-area-in-the-admin-area}

**구독** 영역이 없어서 라이선스를 추가할 수 없습니다. 이 문제는 다음과 같은 경우에 발생할 수 있습니다:

- GitLab Community Edition을 실행 중입니다. 라이선스를 추가하기 전에 Enterprise Edition으로 업그레이드해야 합니다.
- GitLab.com을 사용 중입니다. GitLab Self-Managed 라이선스를 GitLab.com에 추가할 수 없습니다. GitLab.com에서 유료 기능을 사용하려면 [별도의 구독을 구매합니다](../subscriptions/manage_seats.md#gitlabcom-billing-and-usage).

### 갱신 시 사용자가 라이선스 한도 초과 {#users-exceed-license-limit-upon-renewal}

GitLab은 추가 사용자를 구매하도록 요청하는 메시지를 표시합니다. 인스턴스의 사용자 수를 충당할 수 있는 충분한 사용자가 없는 라이선스를 추가하면 이 문제가 발생합니다.

이 문제를 해결하려면 해당 사용자를 충당할 추가 사용자를 구매합니다. 자세한 내용은 [라이선스 FAQ](https://about.gitlab.com/pricing/licensing-faq/)를 읽습니다.

GitLab 14.2 이상에서 라이선스 파일을 사용하는 인스턴스의 경우 다음 규칙이 적용됩니다:

- 라이선스를 초과한 사용자가 라이선스 파일의 사용자의 10% 이하이면 라이선스가 적용되고 다음 갱신에서 초과분을 지불합니다.
- 라이선스를 초과한 사용자가 라이선스 파일의 사용자의 10%를 초과하면 더 많은 사용자를 구매하지 않고는 라이선스를 적용할 수 없습니다.

예를 들어, 100명의 사용자를 위한 라이선스를 구매하면 라이선스를 추가할 때 110명의 사용자를 가질 수 있습니다. 하지만 사용자가 111명인 경우 라이선스를 추가하기 전에 더 많은 사용자를 구매해야 합니다.

### `Start GitLab Ultimate trial`는 라이선스 추가 후에도 여전히 표시됨 {#start-gitlab-ultimate-trial-still-displays-after-adding-license}

이 문제를 해결하려면 [Puma 또는 전체 GitLab 인스턴스를 다시 시작합니다](restart_gitlab.md).
