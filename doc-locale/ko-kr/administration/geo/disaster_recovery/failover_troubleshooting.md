---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 장애 조치 문제 해결
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 장애 조치 중 또는 세컨더리 사이트를 프라이머리 사이트로 승격할 때 오류 수정 {#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site}

다음은 장애 조치 중 또는 세컨더리 사이트를 프라이머리 사이트로 승격할 때 발생할 수 있는 오류 메시지와 해결 전략입니다.

### 메시지: `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` {#message-activerecordrecordinvalid-validation-failed-name-has-already-been-taken}

[**세컨더리** 사이트를 승격](_index.md#step-2-promoting-a-secondary-site)할 때 다음 오류 메시지가 표시될 수 있습니다:

```plaintext
Running gitlab-rake gitlab:geo:set_secondary_as_primary...

rake aborted!
ActiveRecord::RecordInvalid: Validation failed: Name has already been taken
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:236:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:geo:set_secondary_as_primary
(See full trace by running task with --trace)

You successfully promoted this node!
```

`gitlab-rake gitlab:geo:set_secondary_as_primary` 또는 `gitlab-ctl promote-to-primary-node` 명령을 실행할 때 이 메시지가 나타나면 Rails 콘솔을 열고 다음을 실행합니다:

  ```ruby
  Rails.application.load_tasks; nil
  Gitlab::Geo.expire_cache!
  Rake::Task['gitlab:geo:set_secondary_as_primary'].invoke
  ```

### 메시지: ``NoMethodError: undefined method `secondary?' for nil:NilClass`` {#message-nomethoderror-undefined-method-secondary-for-nilnilclass}

[**세컨더리** 사이트를 승격](_index.md#step-2-promoting-a-secondary-site)할 때 다음 오류 메시지가 표시될 수 있습니다:

```plaintext
sudo gitlab-rake gitlab:geo:set_secondary_as_primary

rake aborted!
NoMethodError: undefined method `secondary?' for nil:NilClass
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:232:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:geo:set_secondary_as_primary
(See full trace by running task with --trace)
```

이 명령은 세컨더리 사이트에서만 실행되도록 의도되었으며, 프라이머리 사이트에서 이 명령을 실행하려고 하면 이 오류 메시지가 표시됩니다.

### 만료된 아티팩트 {#expired-artifacts}

어떤 이유로든 Geo **세컨더리** 사이트에 Geo **프라이머리** 사이트보다 더 많은 아티팩트가 있다는 것을 알게 되면 Rake 작업을 사용하여 [고아 아티팩트 파일을 정리](../../raketasks/cleanup.md#remove-orphan-artifact-files)할 수 있습니다.

Geo **세컨더리** 사이트에서 이 명령은 디스크의 고아 파일과 관련된 모든 Geo 레지스트리 레코드도 정리합니다.

### 로그인 오류 수정 {#fixing-sign-in-errors}

#### 메시지:  포함된 리디렉션 URI이 유효하지 않습니다 {#message-the-redirect-uri-included-is-not-valid}

**프라이머리** 사이트의 웹 인터페이스에 로그인할 수 있지만 **세컨더리** 웹 인터페이스에 로그인하려고 할 때 이 오류 메시지가 표시되면 Geo 사이트의 URL이 외부 URL과 일치하는지 확인해야 합니다.

전제 조건:

- 운영자 액세스 권한.

**프라이머리** 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 영향을 받는 **세컨더리** 사이트를 찾아 **편집**을 선택합니다.
1. **URL** 필드가 **Rails nodes of the secondary**에 있는 `/etc/gitlab/gitlab.rb`에서 발견된 `external_url "https://gitlab.example.com"` 값과 일치하는지 확인합니다.

#### 세컨더리 사이트의 SAML 인증이 항상 프라이머리 사이트로 이동합니다 {#authenticating-with-saml-on-the-secondary-site-always-lands-on-the-primary-site}

이 [문제는 일반적으로 GitLab 15.1로 업그레이드할 때 발생](../../../update/versions/gitlab_15_changes.md#1510)합니다. 이 문제를 해결하려면 [Geo에서 인스턴스 전체 SAML을 Single Sign-On으로 구성](../replication/single_sign_on.md#configuring-instance-wide-saml)하는 것을 참조합니다.

## 부분 장애 조치에서 복구 {#recovering-from-a-partial-failover}

세컨더리 Geo 사이트로의 부분 장애 조치는 일시적/과도한 문제로 인한 결과일 수 있습니다. 따라서 먼저 승격 명령을 다시 실행해 봅니다.

1. **세컨더리** 사이트의 모든 Sidekiq, PostgreSQL, Gitaly 및 Rails 노드에 SSH로 연결하고 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. **successful**하면 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격됩니다.

이전 단계가 **not successful** 다음 단계를 진행합니다:

1. **세컨더리** 사이트의 모든 Sidekiq, PostgreSQL, Gitaly 및 Rails 노드에 SSH로 연결하고 다음 작업을 수행합니다:

   - `/etc/gitlab/gitlab-cluster.json` 파일을 다음 내용으로 생성합니다:

     ```shell
     {
       "primary": true,
       "secondary": false
     }
     ```

   - 변경 사항이 적용되도록 GitLab을 다시 구성합니다:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. 성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.
