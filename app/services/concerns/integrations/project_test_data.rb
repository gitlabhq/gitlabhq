# frozen_string_literal: true

module Integrations
  module ProjectTestData
    NoDataError = Class.new(ArgumentError)

    private

    def no_data_error(msg)
      raise NoDataError, msg
    end

    def push_events_data
      Gitlab::DataBuilder::Push.build_sample(project, current_user)
    end

    def tag_push_events_data
      Gitlab::DataBuilder::Push.build_sample(project, current_user, is_tag: true)
    end

    def note_events_data
      note = NotesFinder.new(current_user, project: project, target: project, sort: 'id_desc').execute.first

      no_data_error(s_('TestHooks|Ensure the project has notes.')) unless note.present?

      Gitlab::DataBuilder::Note.build(note, current_user, :create)
    end

    def issues_events_data
      issue = IssuesFinder.new(current_user, project_id: project.id, sort: 'created_desc').execute.first

      no_data_error(s_('TestHooks|Ensure the project has issues.')) unless issue.present?

      issue.to_hook_data(current_user, action: 'open')
    end

    def merge_requests_events_data
      merge_request = MergeRequestsFinder.new(current_user, project_id: project.id, sort: 'created_desc').execute.first

      no_data_error(s_('TestHooks|Ensure the project has merge requests.')) unless merge_request.present?

      merge_request.to_hook_data(current_user, action: 'open')
    end

    def job_events_data
      build = Ci::JobsFinder.new(current_user: current_user, project: project).execute.first

      no_data_error(s_('TestHooks|Ensure the project has CI jobs.')) unless build.present?

      Gitlab::DataBuilder::Build.build(build)
    end

    def pipeline_events_data
      pipeline = Ci::PipelinesFinder.new(project, current_user, order_by: 'id', sort: 'desc').execute.first

      no_data_error(s_('TestHooks|Ensure the project has CI pipelines.')) unless pipeline.present?

      Gitlab::DataBuilder::Pipeline.build(pipeline)
    end

    def wiki_page_events_data
      page = project.wiki.list_pages(limit: 1).first

      no_data_error(s_('TestHooks|Ensure the wiki is enabled and has pages.')) if !project.wiki_enabled? || page.blank?

      Gitlab::DataBuilder::WikiPage.build(page, current_user, 'create')
    end

    def deployment_events_data
      deployment = DeploymentsFinder.new(project: project, order_by: 'created_at', sort: 'desc').execute.first

      no_data_error(s_('TestHooks|Ensure the project has deployments.')) unless deployment.present?

      Gitlab::DataBuilder::Deployment.build(deployment, deployment.status, Time.current)
    end

    def releases_events_data
      release = ReleasesFinder.new(project, current_user, order_by: :created_at, sort: :desc).execute.first

      no_data_error(s_('TestHooks|Ensure the project has releases.')) unless release.present?

      release.to_hook_data('create')
    end

    def emoji_events_data
      no_data_error(s_('TestHooks|Ensure the project has notes.')) unless project.notes.any?

      award_emoji = AwardEmoji.new(
        id: 1,
        name: AwardEmoji::THUMBS_UP,
        user: current_user,
        awardable: project.notes.last,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )

      Gitlab::DataBuilder::Emoji.build(award_emoji, current_user, 'award')
    end

    def access_tokens_events_data
      resource_access_token = PersonalAccessToken.new(
        id: 1,
        name: 'pat_for_webhook_event',
        user: project.bots.first,
        created_at: Time.zone.now,
        updated_at: Time.zone.now,
        expires_at: 2.days.from_now
      )

      Gitlab::DataBuilder::ResourceAccessToken.build(resource_access_token, :expiring, project)
    end

    def vulnerability_events_data
      return unless ::Feature.enabled?(:vulnerabilities_as_webhook_events, project)

      vulnerability_finding_identifiers = [
        Vulnerabilities::FindingIdentifier.new(
          id: 1,
          project_id: project.id,
          identifier: Vulnerabilities::Identifier.new(
            id: 1,
            project: project,
            name: 'Gemnasium-29dce398-220a-4315-8c84-16cd8b6d9b05',
            external_id: '29dce398-220a-4315-8c84-16cd8b6d9b05',
            external_type: 'gemnasium',
            url: 'https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/blob/master/gem/rexml/CVE-2024-41123.yml'
          )
        ),
        Vulnerabilities::FindingIdentifier.new(
          id: 2,
          project_id: project.id,
          identifier: Vulnerabilities::Identifier.new(
            id: 2,
            project: project,
            name: 'CVE-2024-41123',
            external_id: 'CVE-2024-41123',
            external_type: 'cve',
            url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2024-41123'
          )
        )
      ]

      vulnerability_finding = Vulnerabilities::Finding.new(
        id: 1,
        project: project,
        name: 'REXML DoS vulnerability',
        severity: :high,
        report_type: :dependency_scanning,
        metadata_version: '15.1.4',
        location: {
          file: 'Gemfile.lock',
          dependency: {
            package: {
              name: 'rexml'
            },
            version: '3.3.1'
          }
        },
        finding_identifiers: vulnerability_finding_identifiers,
        primary_identifier: vulnerability_finding_identifiers.first.identifier,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )

      vulnerability = Vulnerability.new(
        id: 1,
        author: current_user,
        project: project,
        title: 'REXML DoS vulnerability',
        state: 'confirmed',
        cvss: [
          {
            vector: 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H',
            vendor: 'NVD'
          }
        ],
        severity: :high,
        severity_overridden: false,
        confidence: :unknown,
        report_type: :dependency_scanning,
        findings: [vulnerability_finding],
        confirmed_at: Time.zone.now,
        confirmed_by_id: current_user.id,
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )

      issue = Issue.new(
        iid: 1,
        project_id: project.id,
        namespace: project.namespace,
        author: current_user,
        title: 'REXML ReDoS vulnerability',
        created_at: Time.zone.now,
        updated_at: Time.zone.now
      )

      issue_link = Vulnerabilities::IssueLink.new(
        project_id: project.id,
        vulnerability: vulnerability,
        issue: issue
      )

      vulnerability.issue_links = [issue_link]

      Gitlab::DataBuilder::Vulnerability.build(vulnerability)
    end

    def current_user_events_data
      {
        current_user: current_user
      }
    end

    def project_events_data
      Gitlab::HookData::ProjectBuilder.new(project).build(:create)
    end
  end
end
