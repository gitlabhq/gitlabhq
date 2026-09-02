---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "UI, Rake 작업, Rails 콘솔 또는 API를 사용하여 사용자 비밀번호를 변경합니다."
title: 사용자 비밀번호 재설정
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

UI, Rake 작업, Rails 콘솔 또는 [사용자 API](../api/users.md#modify-a-user)를 사용하여 사용자 비밀번호를 재설정할 수 있습니다.

## 전제 조건 {#prerequisites}

- 인스턴스의 관리자여야 합니다.
- 비밀번호는 모든 [비밀번호 요구 사항](../user/profile/user_passwords.md#password-requirements)을 충족해야 합니다.

## UI 사용 {#use-the-ui}

UI에서 사용자 비밀번호를 재설정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 업데이트할 사용자 계정을 확인하고 **편집**을 선택합니다.
1. **비밀번호** 섹션에서 새 비밀번호를 입력하고 확인합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab이 사용자 비밀번호를 업데이트합니다.

## Rake 작업 사용 {#use-a-rake-task}

Rake 작업으로 사용자 비밀번호를 재설정하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake "gitlab:password:reset"
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```shell
bundle exec rake "gitlab:password:reset"
```

{{< /tab >}}

{{< /tabs >}}

GitLab은 사용자 이름, 비밀번호 및 비밀번호 확인을 요청합니다. 완료되면 사용자 비밀번호가 업데이트됩니다.

Rake 작업은 인수로 사용자 이름을 허용할 수 있습니다. 예를 들어 사용자 이름 `sidneyjones`의 사용자 비밀번호를 재설정하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

  ```shell
  sudo gitlab-rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

  ```shell
  bundle exec rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< /tabs >}}

## Rails 콘솔 사용 {#use-a-rails-console}

Rails 콘솔에서 사용자 비밀번호를 재설정하려면:

전제 조건:

- 관련 사용자 이름, 사용자 ID 또는 이메일 주소를 알아야 합니다.

1. [Rails 콘솔 세션](../administration/operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 사용자를 찾습니다:

   - 사용자 이름별:

     ```ruby
     user = User.find_by_username 'exampleuser'
     ```

   - 사용자 ID별:

     ```ruby
     user = User.find(123)
     ```

   - 이메일 주소별:

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. `user.password` 및 `user.password_confirmation`에 값을 설정하여 비밀번호를 재설정합니다. 예를 들어 새 임의 비밀번호를 설정하려면:

   ```ruby
   new_password = ::User.random_password
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

   새 비밀번호에 특정 값을 설정하려면:

   ```ruby
   new_password = 'examplepassword'
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

1. 선택 사항. 관리자가 사용자의 비밀번호를 변경했음을 사용자에게 알립니다:

   ```ruby
   user.send_only_admin_changed_your_password_notification!
   ```

1. 변경 사항을 저장합니다:

   ```ruby
   user.save!
   ```

1. 콘솔을 종료합니다:

   ```ruby
   exit
   ```

## 루트 비밀번호 재설정 {#reset-the-root-password}

이전에 설명한 [Rake 작업](#use-a-rake-task) 또는 [Rails 콘솔](#use-a-rails-console) 프로세스를 통해 루트 비밀번호를 재설정할 수 있습니다.

- 루트 계정 이름이 변경되지 않았다면 사용자 이름 `root`을 사용합니다.
- 루트 계정 이름이 변경되었고 새 사용자 이름을 모를 경우, 사용자 ID `1`을 사용하여 Rails 콘솔을 사용할 수 있습니다. 거의 모든 경우에 첫 번째 사용자는 기본 관리자 계정입니다.

## 문제 해결 {#troubleshooting}

사용자 비밀번호 재설정 시 문제를 해결하기 위해 다음 정보를 사용합니다.

### 이메일 확인 문제 {#email-confirmation-issues}

새 비밀번호가 작동하지 않으면 이메일 확인 문제일 수 있습니다. Rails 콘솔에서 이 문제를 해결할 수 있습니다. 예를 들어 새 `root` 비밀번호가 작동하지 않는 경우:

1. [Rails 콘솔](../administration/operations/rails_console.md)을 시작합니다.
1. 사용자를 찾고 재확인을 건너뜁니다:

   ```ruby
   user = User.find(1)
   user.skip_reconfirmation!
   ```

1. 다시 로그인해 봅니다.

### 충족되지 않은 비밀번호 요구 사항 {#unmet-password-requirements}

비밀번호가 너무 짧거나 약하거나 복잡성 요구 사항을 충족하지 않을 수 있습니다. 설정하려는 비밀번호가 모든 [비밀번호 요구 사항](../user/profile/user_passwords.md#password-requirements)을 충족하는지 확인합니다.

### 만료된 비밀번호 {#expired-password}

사용자 비밀번호가 이전에 만료된 경우 비밀번호 만료 날짜를 업데이트해야 할 수 있습니다. 자세한 내용은 [LDAP 사용자용 SSH를 사용한 Git fetch 시 비밀번호 만료 오류](../topics/git/troubleshooting_git.md#your-password-expired-error-on-git-fetch-with-ssh-for-ldap-user)를 참조합니다.
