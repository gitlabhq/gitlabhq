---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 'GitLab 관리자: 기능 플래그 뒤에 배포된 GitLab 기능 활성화 및 비활성화'
title: 기능 플래그 뒤에 배포된 GitLab 기능 활성화 및 비활성화
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 기능 플래그 전략을 채택하여 개발 초기 단계에 기능을 배포하므로 점진적으로 출시할 수 있습니다.

기능을 영구적으로 사용 가능하게 하기 전에, 다음과 같은 여러 이유로 인해 기능을 플래그 뒤에 배포할 수 있습니다:

- 기능을 테스트합니다.
- 기능 개발 초기 단계에서 사용자 및 고객으로부터 피드백을 받습니다.
- 사용자 채택도를 평가합니다.
- GitLab의 성능에 미치는 영향을 평가합니다.
- 릴리스 전반에 걸쳐 더 작은 조각으로 빌드합니다.

플래그 뒤의 기능은 일반적으로 점진적으로 출시될 수 있습니다:

1. 기능은 기본적으로 비활성화된 상태로 시작됩니다.
1. 기능이 기본적으로 활성화됩니다.
1. 기능 플래그가 제거됩니다.

이러한 기능을 활성화하거나 비활성화하여 사용자가 기능을 사용하도록 허용하거나 방지할 수 있습니다. 이는 [Rails 콘솔](#how-to-enable-and-disable-features-behind-flags) 이나 [기능 플래그 API](../../api/features.md)에 액세스할 수 있는 GitLab 관리자가 수행할 수 있습니다.

기능 플래그를 비활성화하면 기능이 사용자로부터 숨겨지고 모든 기능이 꺼집니다. 예를 들어, 데이터가 기록되지 않으며 서비스가 실행되지 않습니다.

특정 기능을 사용하다가 버그, 오동작 또는 오류를 발견한 경우, [**provide feedback**](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Docs%20-%20feature%20flag%20feedback%3A%20Feature%20Name&issue[description]=Describe%20the%20problem%20you%27ve%20encountered.%0A%0A%3C!--%20Don%27t%20edit%20below%20this%20line%20--%3E%0A%0A%2Flabel%20~%22docs%5C-comments%22%20)하는 것이 매우 중요하므로 플래그 뒤에 있는 동안 개선하거나 수정할 수 있습니다. GitLab을 업그레이드하면 기능 플래그 상태가 변경될 수 있습니다.

## 개발 중인 기능을 활성화할 때의 위험 {#risks-when-enabling-features-still-in-development}

프로덕션 GitLab 환경에서 비활성화된 기능 플래그를 활성화하기 전에, 관련된 잠재적 위험을 이해하는 것이 중요합니다.

> [!warning]
> 기본적으로 비활성화된 기능을 활성화하면 데이터 손상, 안정성 저하, 성능 저하 및 보안 문제가 발생할 수 있습니다.

기본적으로 비활성화된 기능은 향후 GitLab 버전에서 예고 없이 변경되거나 제거될 수 있습니다.

기본 비활성화 기능 플래그 뒤의 기능은 프로덕션 환경에서 사용할 것을 권장하지 않으며, 기본 비활성화 기능 사용으로 인한 문제는 GitLab 지원의 대상이 아닙니다.

기본적으로 비활성화된 기능에서 발견된 보안 문제는 정기 릴리스에서 패치되며 수정 사항을 백포트하는 것과 관련하여 정기적인 [유지 관리 정책](../../policy/maintenance.md#patch-releases)을 따르지 않습니다.

## 릴리스된 기능을 비활성화할 때의 위험 {#risks-when-disabling-released-features}

대부분의 경우 기능 플래그 코드는 향후 GitLab 버전에서 제거됩니다. 그 시점부터 기능을 비활성화된 상태로 유지할 수 없습니다.

## 플래그 뒤의 기능을 활성화 및 비활성화하는 방법 {#how-to-enable-and-disable-features-behind-flags}

각 기능에는 활성화 및 비활성화하는 데 사용할 수 있는 자체 플래그가 있습니다. 플래그 뒤의 각 기능의 설명서에는 플래그의 상태와 활성화 또는 비활성화 명령을 알려주는 섹션이 포함되어 있습니다.

### GitLab Rails 콘솔 시작 {#start-the-gitlab-rails-console}

플래그 뒤의 기능을 활성화 또는 비활성화하기 위해 먼저 수행해야 할 작업은 GitLab Rails 콘솔에서 세션을 시작하는 것입니다.

Linux 패키지 설치의 경우:

```shell
sudo gitlab-rails console
```

소스에서의 설치의 경우:

```shell
sudo -u git -H bundle exec rails console -e production
```

자세한 내용은 [Rails 콘솔 세션 시작](../operations/rails_console.md#starting-a-rails-console-session)을 참조하세요.

### 기능 활성화 또는 비활성화 {#enable-or-disable-the-feature}

Rails 콘솔 세션이 시작되면 `Feature.enable` 또는 `Feature.disable` 명령을 실행합니다. 특정 플래그는 기능의 설명서에서 찾을 수 있습니다.

기능을 활성화하려면 다음을 실행합니다:

```ruby
Feature.enable(:<feature flag>)
```

예를 들어, `example_feature`이라는 가상 기능 플래그를 활성화하려면:

```ruby
Feature.enable(:example_feature)
```

기능을 비활성화하려면 다음을 실행합니다:

```ruby
Feature.disable(:<feature flag>)
```

예를 들어, `example_feature`이라는 가상 기능 플래그를 비활성화하려면:

```ruby
Feature.disable(:example_feature)
```

일부 기능 플래그는 프로젝트 단위로 활성화 또는 비활성화할 수 있습니다:

```ruby
Feature.enable(:<feature flag>, Project.find(<project id>))
```

예를 들어, 프로젝트 `1234`에 대해 `:example_feature` 기능 플래그를 활성화하려면:

```ruby
Feature.enable(:example_feature, Project.find(1234))
```

일부 기능 플래그는 사용자 단위로 활성화 또는 비활성화할 수 있습니다. 예를 들어, 사용자 `sidney_jones`에 대해 `:example_feature` 플래그를 활성화하려면:

```ruby
Feature.enable(:example_feature, User.find_by_username("sidney_jones"))
```

`Feature.enable`과(와) `Feature.disable`는 항상 `true`을(를) 반환합니다. 애플리케이션이 플래그를 사용하지 않더라도 반환합니다:

```ruby
irb(main):001:0> Feature.enable(:example_feature)
=> true
```

기능이 준비되면 GitLab은 기능 플래그를 제거하며, 활성화 및 비활성화 옵션은 더 이상 존재하지 않습니다. 기능이 모든 인스턴스에서 사용 가능하게 됩니다.

### 기능 플래그가 활성화되어 있는지 확인 {#check-if-a-feature-flag-is-enabled}

플래그가 활성화되었는지 또는 비활성화되었는지 확인하려면 `Feature.enabled?` 또는 `Feature.disabled?`을(를) 사용합니다. 예를 들어, `example_feature`라는 이미 활성화된 기능 플래그의 경우:

```ruby
Feature.enabled?(:example_feature)
=> true
Feature.disabled?(:example_feature)
=> false
```

기능이 준비되면 GitLab은 기능 플래그를 제거하며, 활성화 및 비활성화 옵션은 더 이상 존재하지 않습니다. 기능이 모든 인스턴스에서 사용 가능하게 됩니다.

### 설정된 기능 플래그 보기 {#view-set-feature-flags}

모든 GitLab 관리자 설정 기능 플래그를 볼 수 있습니다:

```ruby
Feature.all
=> [#<Flipper::Feature:198220 name="example_feature", state=:on, enabled_gate_names=[:boolean], adapter=:memoizable>]

# Nice output
Feature.all.map {|f| [f.name, f.state]}
```

### 기능 플래그 설정 해제 {#unset-feature-flag}

기능 플래그를 설정 해제하여 GitLab이 해당 플래그의 현재 기본값으로 돌아가도록 할 수 있습니다:

```ruby
Feature.remove(:example_feature)
=> true
```
