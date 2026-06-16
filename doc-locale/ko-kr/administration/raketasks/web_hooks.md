---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹후크 관리 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 웹후크 관리를 위한 Rake 작업을 제공합니다.

[웹후크로 인한 로컬 네트워크에 대한 요청](../../security/webhooks.md)은 관리자가 허용하거나 차단할 수 있습니다.

## 모든 프로젝트에 웹후크 추가 {#add-a-webhook-to-all-projects}

모든 프로젝트에 웹후크를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production
```

## 네임스페이스의 프로젝트에 웹후크 추가 {#add-a-webhook-to-projects-in-a-namespace}

특정 네임스페이스의 모든 프로젝트에 웹후크를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## 프로젝트에서 웹후크 제거 {#remove-a-webhook-from-projects}

모든 프로젝트에서 웹후크를 제거하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production
```

## 네임스페이스의 프로젝트에서 웹후크 제거 {#remove-a-webhook-from-projects-in-a-namespace}

특정 네임스페이스의 프로젝트에서 웹후크를 제거하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## 모든 웹후크 나열 {#list-all-webhooks}

모든 웹후크를 나열하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list

# source installations
bundle exec rake gitlab:web_hook:list RAILS_ENV=production
```

## 네임스페이스의 프로젝트에 대한 웹후크 나열 {#list-webhooks-for-projects-in-a-namespace}

지정된 네임스페이스의 프로젝트에 대한 모든 웹후크를 나열하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:list NAMESPACE=<namespace> RAILS_ENV=production
```
