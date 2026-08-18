---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Markdown 캐시
description: Markdown 캐시 무효화
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

성능상의 이유로 GitLab은 다음과 같은 필드에서 Markdown 텍스트의 HTML 버전을 캐시합니다:

- 댓글
- 이슈 설명
- 머지 리퀘스트 설명

이러한 캐시된 버전은 `external_url` 구성 옵션이 변경될 때와 같이 오래될 수 있습니다. 캐시된 텍스트의 링크는 여전히 이전 URL을 참조합니다.

## 캐시 무효화 {#invalidate-the-cache}

API 또는 Rails 콘솔을 사용하여 Markdown 캐시를 무효화할 수 있습니다.

### API 사용 {#use-the-api}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

API를 사용하여 기존 캐시를 무효화하려면:

1. `local_markdown_version` 설정을 애플리케이션 설정에서 PUT 요청을 전송하여 증가시킵니다:

   ```shell
   curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
   ```

이 API 엔드포인트에 대한 자세한 내용은 [애플리케이션 설정 업데이트](../api/settings.md#update-application-settings)를 참조하세요.

### Rails 콘솔 사용 {#use-the-rails-console}

전제 조건:

- [Rails 콘솔](operations/rails_console.md) 액세스 권한이 있어야 합니다.

#### 그룹의 경우 {#for-a-group}

그룹의 캐시를 무효화하려면:

1. Rails 콘솔을 시작합니다:

   ```shell
   sudo gitlab-rails console
   ```

1. 업데이트할 그룹을 찾습니다:

   ```ruby
   group = Group.find(<group_id>)
   ```

1. 그룹의 모든 프로젝트에 대한 캐시를 무효화합니다:

   ```ruby
   group.all_projects.each_slice(10) do |projects|
     projects.each do |project|
       # Invalidate issues
       project.issues.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate merge requests
       project.merge_requests.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate notes/comments
       project.notes.update_all(note_html: nil)
     end

     # Pause for one second after updating 10 projects
     sleep 1
   end
   ```

#### 프로젝트의 경우 {#for-a-project}

단일 프로젝트의 캐시를 무효화하려면:

1. Rails 콘솔을 시작합니다:

   ```shell
   sudo gitlab-rails console
   ```

1. 업데이트할 프로젝트를 찾습니다:

   ```ruby
   project = Project.find(<project_id>)
   ```

1. 이슈 무효화:

   ```ruby
   project.issues.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. 머지 리퀘스트 무효화:

   ```ruby
   project.merge_requests.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. 참고와 댓글 무효화:

   ```ruby
   project.notes.update_all(note_html: nil)
   ```
