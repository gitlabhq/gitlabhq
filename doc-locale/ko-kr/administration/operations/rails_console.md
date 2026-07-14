---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rails 콘솔
description: 명령줄에서 GitLab 인스턴스와 상호작용합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab의 핵심에는 [Ruby on Rails 프레임워크를 사용하여 구축한](https://about.gitlab.com/blog/why-we-use-rails-to-build-gitlab/) 웹 애플리케이션이 있습니다. [Rails 콘솔](https://guides.rubyonrails.org/command_line.html#rails-console)은 명령줄에서 GitLab 인스턴스와 상호작용하는 방법을 제공하며, Rails에 내장된 훌륭한 도구에 대한 액세스도 제공합니다.

> [!warning]
> Rails 콘솔은 GitLab과 직접 상호작용합니다. 많은 경우 프로덕션 데이터를 영구적으로 수정, 손상 또는 삭제하는 것을 방지할 수 있는 안전장치가 없습니다. 아무런 결과 없이 Rails 콘솔을 탐색하고 싶다면 테스트 환경에서 이를 수행하는 것을 강력히 권장합니다.

Rails 콘솔은 문제를 해결하거나 GitLab 애플리케이션에 대한 직접 액세스를 통해서만 검색할 수 있는 데이터가 필요한 GitLab 시스템 관리자를 위한 것입니다. Ruby의 기본 지식이 필요합니다(빠른 소개를 위해 [이 30분 튜토리얼](https://try.ruby-lang.org/)을 시도해 보세요). Rails 경험이 있으면 유용하지만 필수는 아닙니다.

## Rails 콘솔 세션 시작 {#starting-a-rails-console-session}

Rails 콘솔 세션을 시작하는 프로세스는 GitLab 설치 유형에 따라 다릅니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rails console
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-rails console
```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

```shell
sudo -u git -H bundle exec rails console -e production
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

```shell
# find the pod
kubectl get pods --namespace <namespace> -lapp=toolbox

# open the Rails console
kubectl exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console
```

{{< /tab >}}

{{< /tabs >}}

콘솔을 종료하려면 다음을 입력하세요: `quit`.

### 자동완성 비활성화 {#disable-autocompletion}

Ruby 자동완성은 터미널의 속도를 저하시킬 수 있습니다. 다음을 원하면:

- 자동완성을 비활성화하려면 `Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = false`을 실행하세요.
- 자동완성을 다시 활성화하려면 `Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = true`을 실행하세요.

## Active Record 로깅 활성화 {#enable-active-record-logging}

다음을 실행하여 Rails 콘솔 세션에서 Active Record 디버그 로깅의 출력을 활성화할 수 있습니다:

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

기본적으로 이전 스크립트는 표준 출력으로 기록됩니다. `$stdout`을 원하는 파일 경로로 바꾸어 출력을 리다이렉션할 로그 파일을 지정할 수 있습니다. 예를 들어 다음 코드는 모든 항목을 `/tmp/output.log`에 기록합니다:

```ruby
ActiveRecord::Base.logger = Logger.new('/tmp/output.log')
```

콘솔에서 실행할 수 있는 모든 Ruby 코드로 트리거되는 데이터베이스 쿼리에 대한 정보를 표시합니다. 다시 로깅을 해제하려면 다음을 실행하세요:

```ruby
ActiveRecord::Base.logger = nil
```

## 속성 {#attributes}

사용 가능한 속성을 보고(`pp`) 형식으로 표시합니다.

예를 들어 사용자의 이름과 이메일 주소를 포함하는 속성을 확인합니다:

```ruby
u = User.find_by_username('someuser')
pp u.attributes
```

부분 출력:

```plaintext
{"id"=>1234,
 "email"=>"someuser@example.com",
 "sign_in_count"=>99,
 "name"=>"S User",
 "username"=>"someuser",
 "first_name"=>nil,
 "last_name"=>nil,
 "bot_type"=>nil}
```

그런 다음 속성을 사용합니다([예를 들어 SMTP 테스트](https://docs.gitlab.com/omnibus/settings/smtp/#testing-the-smtp-configuration)):

```ruby
e = u.email
n = u.name
Notify.test_email(e, "Test email for #{n}", 'Test email').deliver_now
#
Notify.test_email(u.email, "Test email for #{u.name}", 'Test email').deliver_now
```

## 데이터베이스 문 타임아웃 비활성화 {#disable-database-statement-timeout}

현재 Rails 콘솔 세션에 대해 PostgreSQL 문 타임아웃을 비활성화할 수 있습니다.

GitLab 15.11 이상에서 데이터베이스 문 타임아웃을 비활성화하려면 다음을 실행하세요:

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

GitLab 16.0 이상에서는 [기본적으로 GitLab이 두 개의 데이터베이스 연결을 사용합니다](../../update/versions/gitlab_16_changes.md#1600). 데이터베이스 문 타임아웃을 비활성화하려면 다음을 실행하세요:

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
Ci::ApplicationRecord.connection.execute('SET statement_timeout TO 0')
```

단일 데이터베이스 연결을 사용하도록 재구성된 GitLab 16.0 이상을 실행하는 인스턴스는 GitLab 15.11 이상의 코드를 사용하여 데이터베이스 문 타임아웃을 비활성화해야 합니다.

데이터베이스 문 타임아웃 비활성화는 현재 Rails 콘솔 세션에만 영향을 미치며 GitLab 프로덕션 환경 또는 다음 Rails 콘솔 세션에는 유지되지 않습니다.

## Rails 콘솔 세션 기록 출력 {#output-rails-console-session-history}

Rails 콘솔에서 다음 명령을 입력하여 명령 기록을 표시합니다.

```ruby
puts Reline::HISTORY.to_a
```

그런 다음 클립보드에 복사하여 나중에 참조할 수 있도록 저장할 수 있습니다.

## Rails Runner 사용 {#using-the-rails-runner}

GitLab 프로덕션 환경의 컨텍스트에서 일부 Ruby 코드를 실행해야 한다면 [Rails Runner](https://guides.rubyonrails.org/command_line.html#rails-runner)를 사용하여 수행할 수 있습니다. 스크립트 파일을 실행할 때 스크립트는 `git` 사용자가 액세스할 수 있어야 합니다.

명령 또는 스크립트가 완료되면 Rails Runner 프로세스가 종료됩니다. 예를 들어 다른 스크립트 또는 cron 작업에서 실행하는 데 유용합니다.

- Linux 패키지 설치의 경우:

  ```shell
  sudo gitlab-rails runner "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo gitlab-rails runner "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo gitlab-rails runner /path/to/script.rb
  ```

- 직접 컴파일된 설치의 경우:

  ```shell
  sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
  ```

Rails Runner는 콘솔과 동일한 출력을 생성하지 않습니다.

콘솔에서 변수를 설정하면 콘솔은 변수 내용이나 참조된 엔티티의 속성과 같은 유용한 디버그 출력을 생성합니다:

```ruby
irb(main):001:0> user = User.first
=> #<User id:1 @root>
```

Rails Runner는 이를 수행하지 않습니다. 출력을 명시적으로 생성해야 합니다:

```shell
$ sudo gitlab-rails runner "user = User.first"
$ sudo gitlab-rails runner "user = User.first; puts user.username ; puts user.id"
root
1
```

Ruby에 대한 기본 지식이 매우 유용합니다. [이 30분 튜토리얼](https://try.ruby-lang.org/)을 시도하여 빠른 소개를 얻으세요. Rails 경험이 있으면 도움이 되지만 필수는 아닙니다.

## 객체의 특정 메서드 찾기 {#find-specific-methods-for-an-object}

```ruby
Array.methods.select { |m| m.to_s.include? "sing" }
Array.methods.grep(/sing/)
```

## 메서드 소스 찾기 {#find-method-source}

```ruby
instance_of_object.method(:foo).source_location

# Example for when we would call project.private?
project.method(:private?).source_location
```

## 출력 제한 {#limiting-output}

세미콜론(`;`)과 문의 끝에 따라오는 문을 추가하면 기본 암시적 반환 출력을 방지합니다. 이미 명시적으로 세부 정보를 출력하고 있고 많은 반환 출력이 있을 수 있는 경우에 사용할 수 있습니다:

```ruby
puts ActiveRecord::Base.descendants; :ok
Project.select(&:pages_deployed?).each {|p| puts p.path }; true
```

## 마지막 작업의 결과 가져오기 또는 저장 {#get-or-store-the-result-of-last-operation}

밑줄(`_`)은 이전 문의 암시적 반환을 나타냅니다. 이를 사용하여 이전 명령의 출력에서 변수를 빠르게 할당할 수 있습니다:

```ruby
Project.last
# => #<Project id:2537 root/discard>>
project = _
# => #<Project id:2537 root/discard>>
project.id
# => 2537
```

## 작업 시간 측정 {#time-an-operation}

하나 이상의 작업 시간을 측정하려면 다음 형식을 사용하여 자리 표시자 `<operation>`을 선택한 Ruby 또는 Rails 명령으로 바꾸세요:

```ruby
# A single operation
Benchmark.measure { <operation> }

# A breakdown of multiple operations
Benchmark.bm do |x|
  x.report(:label1) { <operation_1> }
  x.report(:label2) { <operation_2> }
end
```

자세한 내용은 벤치마크에 대한 개발자 설명서를 검토하세요.

## Active Record 객체 {#active-record-objects}

### 데이터베이스에 유지된 객체 조회 {#looking-up-database-persisted-objects}

Rails는 내부적으로 [Active Record](https://guides.rubyonrails.org/active_record_basics.html)를 사용하여 애플리케이션 객체를 PostgreSQL 데이터베이스에 읽고, 쓰고, 매핑하는 객체 관계형 매핑 시스템입니다. 이 매핑은 Rails 앱에 정의된 Ruby 클래스인 Active Record 모델에 의해 처리됩니다. GitLab의 경우 모델 클래스는 `/opt/gitlab/embedded/service/gitlab-rails/app/models`에서 찾을 수 있습니다.

수행된 기본 데이터베이스 쿼리를 볼 수 있도록 Active Record에 대한 디버그 로깅을 활성화해 보겠습니다:

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

이제 데이터베이스에서 사용자를 검색해 봅시다:

```ruby
user = User.find(1)
```

반환되는 내용:

```ruby
D, [2020-03-05T16:46:25.571238 #910] DEBUG -- :   User Load (1.8ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1
=> #<User id:1 @root>
```

데이터베이스의 `users` 테이블을 쿼리했으며 해당 `id` 열의 값이 `1`인 행을 찾았고, Active Record가 해당 데이터베이스 레코드를 상호작용할 수 있는 Ruby 객체로 변환했음을 확인할 수 있습니다. 다음 중 일부를 시도해 보세요:

- `user.username`
- `user.created_at`
- `user.admin`

관례에 따라 열 이름은 Ruby 객체 속성으로 직접 변환되므로 `user.<column_name>`을 수행하여 속성의 값을 볼 수 있어야 합니다.

관례에 따라 Active Record 클래스 이름(단수 및 카멜 케이스)은 테이블 이름(복수 및 스네이크 케이스)으로 직접 매핑되며 그 반대도 마찬가지입니다. 예를 들어 `users` 테이블은 `User` 클래스에 매핑되고 `application_settings` 테이블은 `ApplicationSetting` 클래스에 매핑됩니다.

Rails 데이터베이스 스키마에서 테이블 및 열 이름 목록을 찾을 수 있으며 `/opt/gitlab/embedded/service/gitlab-rails/db/schema.rb`에서 사용할 수 있습니다.

속성 이름으로 데이터베이스에서 객체를 조회할 수도 있습니다:

```ruby
user = User.find_by(username: 'root')
```

반환되는 내용:

```ruby
D, [2020-03-05T17:03:24.696493 #910] DEBUG -- :   User Load (2.1ms)  SELECT "users".* FROM "users" WHERE "users"."username" = 'root' LIMIT 1
=> #<User id:1 @root>
```

다음을 시도해 보세요:

- `User.find_by(username: 'root')`
- `User.where.not(admin: true)`
- `User.where('created_at < ?', 7.days.ago)`

마지막 두 명령이 여러 `User` 객체를 포함하는 것으로 보이는 `ActiveRecord::Relation` 객체를 반환했음을 알아챘습니까?

지금까지 우리는 `.find` 또는 `.find_by`를 사용해 왔으며, 이들은 단일 객체만 반환하도록 설계되었습니다(생성된 SQL 쿼리에서 `LIMIT 1`를 알아차렸습니까?). `.where`는 객체 컬렉션을 가져오는 것이 바람직할 때 사용됩니다.

관리자가 아닌 사용자의 컬렉션을 가져와서 어떤 작업을 할 수 있는지 살펴봅시다:

```ruby
users = User.where.not(admin: true)
```

반환되는 내용:

```ruby
D, [2020-03-05T17:11:16.845387 #910] DEBUG -- :   User Load (2.8ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE LIMIT 11
=> #<ActiveRecord::Relation [#<User id:3 @support-bot>, #<User id:7 @alert-bot>, #<User id:5 @carrie>, #<User id:4 @bernice>, #<User id:2 @anne>]>
```

이제 다음을 시도해 보세요:

- `users.count`
- `users.order(created_at: :desc)`
- `users.where(username: 'support-bot')`

마지막 명령에서 더 복잡한 쿼리를 생성하기 위해 `.where` 문을 연결할 수 있음을 확인할 수 있습니다. 반환된 컬렉션이 단일 객체만 포함하더라도 이를 직접 상호작용할 수 없습니다:

```ruby
users.where(username: 'support-bot').username
```

반환되는 내용:

```ruby
Traceback (most recent call last):
        1: from (irb):37
D, [2020-03-05T17:18:25.637607 #910] DEBUG -- :   User Load (1.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' LIMIT 11
NoMethodError (undefined method `username' for #<ActiveRecord::Relation [#<User id:3 @support-bot>]>)
Did you mean?  by_username
```

컬렉션에서 단일 객체를 검색하기 위해 `.first` 메서드를 사용하여 컬렉션의 첫 번째 항목을 가져오겠습니다:

```ruby
users.where(username: 'support-bot').first.username
```

이제 원하는 결과를 얻었습니다:

```ruby
D, [2020-03-05T17:18:30.406047 #910] DEBUG -- :   User Load (2.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' ORDER BY "users"."id" ASC LIMIT 1
=> "support-bot"
```

Active Record를 사용하여 데이터베이스에서 데이터를 검색하는 다양한 방법에 대한 자세한 내용은 [Active Record Query Interface 설명서](https://guides.rubyonrails.org/active_record_querying.html)를 참조하세요.

## Active Record 모델을 사용하여 데이터베이스 쿼리 {#query-the-database-using-an-active-record-model}

```ruby
m = Model.where('attribute like ?', 'ex%')

# for example to query the projects
projects = Project.where('path like ?', 'Oumua%')
```

### Active Record 객체 수정 {#modifying-active-record-objects}

이전 섹션에서 Active Record를 사용하여 데이터베이스 레코드를 검색하는 방법을 배웠습니다. 이제 데이터베이스에 변경 사항을 기록하는 방법을 배워봅시다.

먼저 `root` 사용자를 검색해 봅시다:

```ruby
user = User.find_by(username: 'root')
```

다음으로 사용자의 비밀번호를 업데이트해 봅시다:

```ruby
user.password = 'password'
user.save
```

반환되는 내용:

```ruby
Enqueued ActionMailer::MailDeliveryJob (Job ID: 05915c4e-c849-4e14-80bb-696d5ae22065) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007f42d8ccebe8 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
```

여기서 `.save` 명령이 `true`를 반환했으므로 비밀번호 변경이 데이터베이스에 성공적으로 저장되었음을 나타냅니다.

저장 작업이 다른 작업을 트리거했다는 것을 알 수 있습니다(이 경우 이메일 알림을 전달하기 위한 백그라운드 작업). 이것은 Active Record 객체 수명 주기의 이벤트에 대한 응답으로 실행되도록 지정된 코드인 [Active Record 콜백](https://guides.rubyonrails.org/active_record_callbacks.html)의 예입니다. 이것이 데이터의 직접 변경이 필요할 때 Rails 콘솔이 선호되는 이유이며, 직접 데이터베이스 쿼리를 통해 수행된 변경 사항은 이러한 콜백을 트리거하지 않습니다.

한 줄에서 속성을 업데이트할 수도 있습니다:

```ruby
user.update(password: 'password')
```

또는 한 번에 여러 속성을 업데이트합니다:

```ruby
user.update(password: 'password', email: 'hunter2@example.com')
```

이제 다른 것을 시도해 봅시다:

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save
```

이는 `false`를 반환하므로 변경 사항이 데이터베이스에 저장되지 않았음을 나타냅니다. 확실히 알고 싶겠지만 확인해 봅시다:

```ruby
user.save!
```

반환되어야 하는 내용:

```ruby
Traceback (most recent call last):
        1: from (irb):64
ActiveRecord::RecordInvalid (Validation failed: Password confirmation doesn't match Password)
```

아하! [Active Record 검증](https://guides.rubyonrails.org/active_record_validations.html)을 트리거했습니다. 검증은 원치 않는 데이터가 데이터베이스에 저장되는 것을 방지하기 위해 애플리케이션 수준에서 시행되는 비즈니스 로직이며 대부분의 경우 문제 입력을 수정하는 방법을 알려주는 유용한 메시지가 함께 제공됩니다.

또한 bang(Ruby 용어로 `!`)을 `.update`에 추가할 수 있습니다:

```ruby
user.update!(password: 'password', password_confirmation: 'hunter2')
```

`!`로 끝나는 메서드 이름을 일반적으로 "bang 메서드"라고 합니다. 관례에 따라 bang은 메서드가 자신이 작동하는 객체를 직접 수정하며, 변환된 결과를 반환하고 기본 객체를 그대로 두지 않음을 나타냅니다. 데이터베이스에 쓰는 Active Record 메서드의 경우 bang 메서드는 추가 기능도 제공합니다. 단순히 `false`을 반환하는 대신 오류가 발생할 때마다 명시적 예외를 발생시킵니다.

검증을 완전히 건너뛸 수도 있습니다:

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save!(validate: false)
```

검증은 사용자 제공 데이터의 무결성과 일관성을 보장하기 위해 시행되므로 권장되지 않습니다.

검증 오류로 인해 전체 객체가 데이터베이스에 저장되지 않습니다. 이 중 일부를 아래 섹션에서 볼 수 있습니다. 폼을 제출할 때 GitLab UI에서 신비로운 빨간색 배너가 표시되면 문제의 근본 원인을 파악하는 가장 빠른 방법이 될 수 있습니다.

### Active Record 객체와 상호작용 {#interacting-with-active-record-objects}

결국 Active Record 객체는 표준 Ruby 객체일 뿐입니다. 따라서 임의의 작업을 수행하는 메서드를 정의할 수 있습니다.

예를 들어 GitLab 개발자는 2단계 인증을 지원하는 일부 메서드를 추가했습니다:

```ruby
def disable_two_factor!
  transaction do
    update(
      otp_required_for_login:      false,
      encrypted_otp_secret:        nil,
      encrypted_otp_secret_iv:     nil,
      encrypted_otp_secret_salt:   nil,
      otp_grace_period_started_at: nil,
      otp_backup_codes:            nil
    )
    self.second_factor_webauthn_registrations.destroy_all # rubocop: disable DestroyAll
  end
end

def two_factor_enabled?
  two_factor_otp_enabled? || two_factor_webauthn_enabled?
end
```

(참조: `/opt/gitlab/embedded/service/gitlab-rails/app/models/user.rb`)

그런 다음 모든 사용자 객체에서 이 메서드를 사용할 수 있습니다:

```ruby
user = User.find_by(username: 'root')
user.two_factor_enabled?
user.disable_two_factor!
```

일부 메서드는 GitLab이 사용하는 gem(Ruby 소프트웨어 패키지)으로 정의됩니다. 예를 들어 GitLab이 사용자 상태를 관리하는 데 사용하는 [StateMachines](https://github.com/state-machines/state_machines-activerecord) gem:

```ruby
state_machine :state, initial: :active do
  event :block do

  ...

  event :activate do

  ...

end
```

시도해 봅시다:

```ruby
user = User.find_by(username: 'root')
user.state
user.block
user.state
user.activate
user.state
```

앞서 검증 오류로 인해 전체 객체가 데이터베이스에 저장되지 않는다고 했습니다. 이것이 예상치 못한 상호작용을 어떻게 유발할 수 있는지 봅시다:

```ruby
user.password = 'password'
user.password_confirmation = 'hunter2'
user.block
```

`false`이 반환되었습니다! 앞서 했던 방식대로 bang을 추가하여 어떻게 되었는지 알아봅시다:

```ruby
user.block!
```

반환되는 내용:

```ruby
Traceback (most recent call last):
        1: from (irb):87
StateMachines::InvalidTransition (Cannot transition state via :block from :active (Reason(s): Password confirmation doesn't match Password))
```

완전히 별개의 속성으로 느껴지는 검증 오류가 사용자를 어떤 방식으로든 업데이트하려고 할 때 돌아옵니다.

실제로 이것은 GitLab 관리 설정에서 가끔 발생합니다. 검증이 GitLab 업데이트에서 추가되거나 변경되어 이전에 저장된 설정이 이제 검증에 실패합니다. UI를 통해 한 번에 설정의 하위 집합만 업데이트할 수 있으므로 이 경우 정상 상태로 돌아가는 유일한 방법은 Rails 콘솔을 통한 직접 조작입니다.

### 일반적으로 사용되는 Active Record 모델 및 객체를 조회하는 방법 {#commonly-used-active-record-models-and-how-to-look-up-objects}

**Get a user by primary email address or username**:

```ruby
User.find_by(email: 'admin@example.com')
User.find_by(username: 'root')
```

**Get a user by primary OR secondary email address**:

```ruby
User.find_by_any_email('user@example.com')
```

`find_by_any_email` 메서드는 Rails에서 제공하는 기본 메서드가 아니라 GitLab 개발자가 추가한 사용자 지정 메서드입니다.

**Get a collection of administrator users**:

```ruby
User.admins
```

`admins`은(는) 내부적으로 `where(admin: true)`을(를) 수행하는 [범위 편의 메서드](https://guides.rubyonrails.org/active_record_querying.html#scopes)입니다.

**Get a project by its path**:

```ruby
Project.find_by_full_path('group/subgroup/project')
```

`find_by_full_path`은(는) Rails에서 제공하는 기본 메서드가 아니라 GitLab 개발자가 추가한 사용자 지정 메서드입니다.

**Get a project's issue or merge request by its numeric ID**:

```ruby
project = Project.find_by_full_path('group/subgroup/project')
project.issues.find_by(iid: 42)
project.merge_requests.find_by(iid: 42)
```

`iid`은(는) "internal ID"를 의미하며 각 GitLab 프로젝트에 대해 이슈 및 머지 리퀘스트 ID를 범위 내에 두는 방법입니다.

**Get a group by its path**:

```ruby
Group.find_by_full_path('group/subgroup')
```

**Get a group's related groups**:

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get a group's parent group
group.parent

# Get a group's child groups
group.children
```

**Get a group's projects**:

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get group's immediate child projects
group.projects

# Get group's child projects, including those in subgroups
group.all_projects
```

**Get CI pipeline or builds**:

```ruby
Ci::Pipeline.find(4151)
Ci::Build.find(66124)
```

파이프라인 및 작업 ID 숫자는 GitLab 인스턴스 전체에서 전역적으로 증가하므로 이슈 또는 머지 리퀘스트와 달리 내부 ID 속성을 사용하여 조회할 필요가 없습니다.

**Get the current application settings object**:

```ruby
ApplicationSetting.current
```

### `irb`에서 객체 열기 {#open-object-in-irb}

> [!warning]
> 올바르게 실행하지 않거나 적절한 조건에서 실행하지 않으면 데이터를 변경하는 명령이 손상을 유발할 수 있습니다. 항상 먼저 테스트 환경에서 명령을 실행하고 복원할 준비가 된 백업 인스턴스를 확보하세요.

객체의 컨텍스트에 있을 때 메서드를 거치는 것이 더 쉬울 수도 있습니다. `Object`의 네임스페이스에 shim을 삽입하여 모든 객체의 컨텍스트에서 `irb`을(를) 열 수 있습니다:

```ruby
Object.define_method(:irb) { binding.irb }

project = Project.last
# => #<Project id:2537 root/discard>>
project.irb
# Notice new context
irb(#<Project>)> web_url
# => "https://gitlab-example/root/discard"
```

## 문제 해결 {#troubleshooting}

### Rails Runner `syntax error` {#rails-runner-syntax-error}

`gitlab-rails` 명령은 기본적으로 비루트 계정 및 그룹을 사용하여 Rails Runner를 실행합니다: `git:git`.

비루트 계정이 `gitlab-rails runner`에 전달된 Ruby 스크립트 파일명을 찾을 수 없으면 파일에 액세스할 수 없다는 오류가 아닌 구문 오류가 발생할 수 있습니다.

이 문제의 일반적인 이유는 스크립트가 루트 계정의 홈 디렉터리에 배치되었기 때문입니다.

`runner`는 경로 및 파일 매개 변수를 Ruby 코드로 구문 분석하려고 합니다.

예를 들어:

```plaintext
[root ~]# echo 'puts "hello world"' > ./helloworld.rb
[root ~]# sudo gitlab-rails runner ./helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: syntax error, unexpected '.'
./helloworld.rb
^
[root ~]# sudo gitlab-rails runner /root/helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: unknown regexp options - hllwrld
[root ~]# mv ~/helloworld.rb /tmp
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
hello world
```

디렉터리에 액세스할 수 있지만 파일에 액세스할 수 없는 경우 의미 있는 오류가 생성되어야 합니다:

```plaintext
[root ~]# chmod 400 /tmp/helloworld.rb
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
Traceback (most recent call last):
      [traceback removed]
/opt/gitlab/..../runner_command.rb:42:in `load': cannot load such file -- /tmp/helloworld.rb (LoadError)
```

이와 유사한 오류가 발생한 경우:

```plaintext
[root ~]# sudo gitlab-rails runner helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

undefined local variable or method `helloworld' for main:Object
```

파일을 `/tmp` 디렉터리로 이동하거나 사용자 `git`가 소유한 새 디렉터리를 만들고 아래에 설명된 대로 스크립트를 해당 디렉터리에 저장할 수 있습니다:

```shell
sudo mkdir /scripts
sudo mv /script_path/helloworld.rb /scripts
sudo chown -R git:git /scripts
sudo chmod 700 /scripts
sudo gitlab-rails runner /scripts/helloworld.rb
```

### 필터링된 콘솔 출력 {#filtered-console-output}

콘솔의 일부 출력은 변수, 로그 또는 비밀과 같은 특정 값의 누수를 방지하기 위해 기본적으로 필터링될 수 있습니다. 이 출력은 `[FILTERED]`로 표시됩니다. 예를 들어:

```plaintext
> Plan.default.actual_limits
=> ci_instance_level_variables: "[FILTERED]",
```

필터링을 해결하려면 객체에서 직접 값을 읽으세요. 예를 들어:

```plaintext
> Plan.default.limits.ci_instance_level_variables
=> 25
```
