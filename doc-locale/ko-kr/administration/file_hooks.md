---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파일 훅
description: "GitLab Self-Managed 인스턴스를 외부 서비스와 통합하기 위한 사용자 지정 파일 훅을 만듭니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

사용자 지정 파일 훅을 사용하여 GitLab 소스 코드를 수정하지 않고 사용자 지정 통합을 도입합니다.

파일 훅은 각 이벤트에서 실행됩니다. 파일 훅의 코드에서 이벤트나 프로젝트를 필터링하고 필요한 만큼 많은 파일 훅을 만들 수 있습니다. 각 파일 훅은 이벤트 발생 시 GitLab에 의해 비동기적으로 트리거됩니다. 이벤트 목록은 [시스템 훅](system_hooks.md) 및 [웹후크](../user/project/integrations/webhook_events.md) 문서를 참조하세요.

> [!note]
> 파일 훅은 GitLab 서버의 파일 시스템에서 구성해야 합니다. GitLab 서버 관리자만 이러한 작업을 완료할 수 있습니다. 파일 시스템에 액세스할 수 없는 경우 [시스템 훅](system_hooks.md) 또는 [웹후크](../user/project/integrations/webhooks.md)를 옵션으로 살펴봅니다.

자신의 파일 훅을 작성하고 지원하는 대신 GitLab 소스 코드를 직접 변경하고 업스트림에 기여할 수 있습니다. 이렇게 하면 기능이 여러 버전에서 보존되고 테스트로 적용됩니다.

## 사용자 지정 파일 훅 설정 {#set-up-a-custom-file-hook}

파일 훅은 `file_hooks` 디렉터리에 있어야 합니다. 하위 디렉터리는 무시됩니다. [`example` 디렉터리의 예제를 `file_hooks` 아래에서 찾습니다](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples).

사용자 지정 훅을 설정하려면:

1. Sidekiq 구성 요소를 실행하는 GitLab 서버에서 플러그인 디렉터리를 찾습니다. 자체 컴파일된 설치의 경우 경로는 보통 `/home/git/gitlab/file_hooks/`입니다. Linux 패키지 설치의 경우 경로는 보통 `/opt/gitlab/embedded/service/gitlab-rails/file_hooks`입니다.

   [여러 서버가 있는 구성](reference_architectures/_index.md)의 경우 각 GitLab 애플리케이션(Rails) 및 Sidekiq 서버에 훅 파일이 있어야 합니다.

1. `file_hooks` 디렉터리 내에서 공백이나 특수 문자 없이 원하는 이름의 파일을 만듭니다.
1. 훅 파일을 실행 가능하게 만들고 Git 사용자가 소유하는지 확인합니다.
1. 파일 훅이 예상대로 작동하도록 코드를 작성합니다. 모든 언어로 작성할 수 있으며 맨 위의 'shebang'이 언어 유형을 올바르게 반영하는지 확인합니다. 예를 들어 스크립트가 Ruby인 경우 shebang은 아마도 `#!/usr/bin/env ruby`입니다.
1. 파일 훅의 데이터는 `STDIN`에 JSON으로 제공됩니다. 이는 [시스템 훅](system_hooks.md)과 정확히 동일합니다.

파일 훅 코드가 제대로 구현되어 있다면 훅이 적절하게 실행됩니다. 파일 훅 파일 목록은 각 이벤트에 대해 업데이트됩니다. 새 파일 훅을 적용하기 위해 GitLab을 다시 시작할 필요가 없습니다.

파일 훅이 0이 아닌 종료 코드로 실행되거나 실행에 실패하면 메시지가 다음에 기록됩니다:

- 자체 컴파일된 설치의 경우 `log/file_hook.log`입니다.
- Linux 패키지 설치의 경우 `gitlab-rails/file_hook.log`입니다.

이 파일은 파일 훅이 0이 아닌 상태로 종료된 경우에만 만들어집니다. 파일 훅이 실행될 때 각 `FileHookWorker` 시작에 대해 Sidekiq 로그 `gitlab/sidekiq/current`에 항목이 추가됩니다. 이 항목에는 이벤트 및 실행된 스크립트의 세부 정보가 포함됩니다.

## 파일 훅 예제 {#file-hook-example}

이 예제는 `project_create` 이벤트에만 응답하며 GitLab 인스턴스는 관리자에게 새 프로젝트가 생성되었음을 알립니다.

```ruby
#!/opt/gitlab/embedded/bin/ruby
# By using the embedded ruby version we eliminate the possibility that our chosen language
# would be unavailable from
require 'json'
require 'mail'

# The incoming variables are in JSON format so we need to parse it first.
ARGS = JSON.parse($stdin.read)

# We only want to trigger this file hook on the event project_create
return unless ARGS['event_name'] == 'project_create'

# We will inform our admins of our gitlab instance that a new project is created
Mail.deliver do
  from    'info@gitlab_instance.com'
  to      'admin@gitlab_instance.com'
  subject "new project " + ARGS['name']
  body    ARGS['owner_name'] + 'created project ' + ARGS['name']
end
```

## 유효성 검사 예제 {#validation-example}

자신의 파일 훅을 작성하는 것은 까다로울 수 있으며 시스템을 변경하지 않고 확인할 수 있으면 더 쉽습니다. Rake 작업이 제공되므로 프로덕션에서 사용하기 전에 스테이징 환경에서 파일 훅을 테스트하는 데 사용할 수 있습니다. Rake 작업은 샘플 데이터를 사용하고 각 파일 훅을 실행합니다. 출력은 시스템이 파일 훅을 보는지, 오류 없이 실행되었는지 확인하기에 충분해야 합니다.

```shell
# Omnibus installations
sudo gitlab-rake file_hooks:validate

# Installations from source
cd /home/git/gitlab
bundle exec rake file_hooks:validate RAILS_ENV=production
```

출력 예제:

```plaintext
Validating file hooks from /file_hooks directory
* /home/git/gitlab/file_hooks/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/file_hooks/save_to_file.rb failure (non-zero exit code)
```

## 관련 항목 {#related-topics}

- [서버 훅](server_hooks.md)
- [시스템 훅](system_hooks.md)
