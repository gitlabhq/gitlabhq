---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 인스턴스 관리자는 자신의 GitLab 인스턴스에 대한 사용자 지정 이슈 종료 패턴을 구성할 수 있습니다.
title: 이슈 종료 패턴
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> 이슈 종료 패턴에 대한 사용자 설명서는 [이슈 자동으로 종료](../user/project/issues/managing_issues.md#closing-issues-automatically)를 참조하세요.

커밋 또는 머지 리퀘스트가 하나 이상의 이슈를 해결할 때, 커밋 또는 머지 리퀘스트가 프로젝트의 기본 브랜치에 병합되면 GitLab은 이러한 이슈를 종료할 수 있습니다. [기본 이슈 종료 패턴](../user/project/issues/managing_issues.md#default-closing-pattern)은 다양한 단어를 포함하며, 관리자는 필요에 따라 단어 목록을 구성할 수 있습니다.

## 이슈 종료 패턴 변경 {#change-the-issue-closing-pattern}

기본 이슈 종료 패턴을 필요에 맞게 변경하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `gitlab_rails['gitlab_issue_closing_pattern']` 값을 변경합니다:

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집하고 `issueClosingPattern` 값을 변경합니다:

   ```yaml
   global:
     appConfig:
       issueClosingPattern: "<regular_expression>"
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집하고 `gitlab_rails['gitlab_issue_closing_pattern']` 값을 변경합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 `issue_closing_pattern` 값을 변경합니다:

   ```yaml
   production: &base
     gitlab:
       issue_closing_pattern: "<regular_expression>"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

이슈 종료 패턴을 테스트하려면 [Rubular](https://rubular.com)를 사용합니다. Rubular는 `%{issue_ref}`를 이해하지 못합니다. 패턴을 테스트할 때 이 문자열을 `#\d+`으로 바꾸면, `#123`과 같은 로컬 이슈 참조만 일치합니다.
