# frozen_string_literal: true
require 'slack-notifier'

module ChatMessage
  class PipelineMessage < BaseMessage
    MAX_VISIBLE_JOBS = 10

    attr_reader :user
    attr_reader :ref_type
    attr_reader :ref
    attr_reader :status
    attr_reader :detailed_status
    attr_reader :duration
    attr_reader :finished_at
    attr_reader :pipeline_id
    attr_reader :failed_stages
    attr_reader :failed_jobs

    attr_reader :project
    attr_reader :commit
    attr_reader :committer
    attr_reader :pipeline

    def initialize(data)
      super

      @user = data[:user]
      @user_name = data.dig(:user, :username) || 'API'

      pipeline_attributes = data[:object_attributes]
      @ref_type = pipeline_attributes[:tag] ? 'tag' : 'branch'
      @ref = pipeline_attributes[:ref]
      @status = pipeline_attributes[:status]
      @detailed_status = pipeline_attributes[:detailed_status]
      @duration = pipeline_attributes[:duration].to_i
      @finished_at = pipeline_attributes[:finished_at] ? Time.parse(pipeline_attributes[:finished_at]).to_i : nil
      @pipeline_id = pipeline_attributes[:id]
      @failed_jobs = Array(data[:builds]).select { |b| b[:status] == 'failed' }.reverse # Show failed jobs from oldest to newest
      @failed_stages = @failed_jobs.map { |j| j[:stage] }.uniq

      @project = Project.find(data[:project][:id])
      @commit = project.commit_by(oid: data[:commit][:id])
      @committer = commit.committer
      @pipeline = Ci::Pipeline.find(pipeline_id)
    end

    def pretext
      ''
    end

    def attachments
      return message if markdown

      return [{ text: format(message), color: attachment_color }] unless fancy_notifications?

      [{
        fallback: format(message),
        color: attachment_color,
        author_name: user_combined_name,
        author_icon: user_avatar,
        author_link: author_url,
        title: s_("ChatMessage|Pipeline #%{pipeline_id} %{humanized_status} in %{duration}") %
          {
            pipeline_id: pipeline_id,
            humanized_status: humanized_status,
            duration: pretty_duration(duration)
          },
        title_link: pipeline_url,
        fields: attachments_fields,
        footer: project.name,
        footer_icon: project.avatar_url,
        ts: finished_at
      }]
    end

    def activity
      {
        title: s_("ChatMessage|Pipeline %{pipeline_link} of %{ref_type} %{branch_link} by %{user_combined_name} %{humanized_status}") %
          {
            pipeline_link: pipeline_link,
            ref_type: ref_type,
            branch_link: branch_link,
            user_combined_name: user_combined_name,
            humanized_status: humanized_status
          },
        subtitle: s_("ChatMessage|in %{project_link}") % { project_link: project_link },
        text: s_("ChatMessage|in %{duration}") % { duration: pretty_duration(duration) },
        image: user_avatar || ''
      }
    end

    private

    def fancy_notifications?
      Feature.enabled?(:fancy_pipeline_slack_notifications, default_enabled: true)
    end

    def failed_stages_field
      {
        title: s_("ChatMessage|Failed stage").pluralize(failed_stages.length),
        value: Slack::Notifier::LinkFormatter.format(failed_stages_links),
        short: true
      }
    end

    def failed_jobs_field
      {
        title: s_("ChatMessage|Failed job").pluralize(failed_jobs.length),
        value: Slack::Notifier::LinkFormatter.format(failed_jobs_links),
        short: true
      }
    end

    def yaml_error_field
      {
        title: s_("ChatMessage|Invalid CI config YAML file"),
        value: pipeline.yaml_errors,
        short: false
      }
    end

    def attachments_fields
      fields = [
        {
          title: ref_type == "tag" ? s_("ChatMessage|Tag") : s_("ChatMessage|Branch"),
          value: Slack::Notifier::LinkFormatter.format(ref_name_link),
          short: true
        },
        {
          title: s_("ChatMessage|Commit"),
          value: Slack::Notifier::LinkFormatter.format(commit_link),
          short: true
        }
      ]

      fields << failed_stages_field if failed_stages.any?
      fields << failed_jobs_field if failed_jobs.any?
      fields << yaml_error_field if pipeline.has_yaml_errors?

      fields
    end

    def message
      s_("ChatMessage|%{project_link}: Pipeline %{pipeline_link} of %{ref_type} %{branch_link} by %{user_combined_name} %{humanized_status} in %{duration}") %
        {
          project_link: project_link,
          pipeline_link: pipeline_link,
          ref_type: ref_type,
          branch_link: branch_link,
          user_combined_name: user_combined_name,
          humanized_status: humanized_status,
          duration: pretty_duration(duration)
        }
    end

    def humanized_status
      if fancy_notifications?
        case status
        when 'success'
          detailed_status == "passed with warnings" ? s_("ChatMessage|has passed with warnings") : s_("ChatMessage|has passed")
        when 'failed'
          s_("ChatMessage|has failed")
        else
          status
        end
      else
        case status
        when 'success'
          s_("ChatMessage|passed")
        when 'failed'
          s_("ChatMessage|failed")
        else
          status
        end
      end
    end

    def attachment_color
      if fancy_notifications?
        case status
        when 'success'
          detailed_status == 'passed with warnings' ? 'warning' : 'good'
        else
          'danger'
        end
      else
        case status
        when 'success'
          'good'
        else
          'danger'
        end
      end
    end

    def branch_url
      "#{project_url}/commits/#{ref}"
    end

    def branch_link
      "[#{ref}](#{branch_url})"
    end

    def project_url
      project.web_url
    end

    def project_link
      "[#{project.name}](#{project_url})"
    end

    def pipeline_failed_jobs_url
      "#{project_url}/pipelines/#{pipeline_id}/failures"
    end

    def pipeline_url
      if fancy_notifications? && failed_jobs.any?
        pipeline_failed_jobs_url
      else
        "#{project_url}/pipelines/#{pipeline_id}"
      end
    end

    def pipeline_link
      "[##{pipeline_id}](#{pipeline_url})"
    end

    def job_url(job)
      "#{project_url}/-/jobs/#{job[:id]}"
    end

    def job_link(job)
      "[#{job[:name]}](#{job_url(job)})"
    end

    def failed_jobs_links
      failed = failed_jobs.slice(0, MAX_VISIBLE_JOBS)
      truncated = failed_jobs.slice(MAX_VISIBLE_JOBS, failed_jobs.size)

      failed_links = failed.map { |job| job_link(job) }

      unless truncated.blank?
        failed_links << s_("ChatMessage|and [%{count} more](%{pipeline_failed_jobs_url})") % {
          count: truncated.size,
          pipeline_failed_jobs_url: pipeline_failed_jobs_url
        }
      end

      failed_links.join(I18n.translate(:'support.array.words_connector'))
    end

    def stage_link(stage)
      # All stages link to the pipeline page
      "[#{stage}](#{pipeline_url})"
    end

    def failed_stages_links
      failed_stages.map { |s| stage_link(s) }.join(I18n.translate(:'support.array.words_connector'))
    end

    def commit_url
      Gitlab::UrlBuilder.build(commit)
    end

    def commit_link
      "[#{commit.title}](#{commit_url})"
    end

    def commits_page_url
      "#{project_url}/commits/#{ref}"
    end

    def ref_name_link
      "[#{ref}](#{commits_page_url})"
    end

    def author_url
      return unless user && committer

      Gitlab::UrlBuilder.build(committer)
    end
  end
end
