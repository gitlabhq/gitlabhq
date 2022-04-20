# frozen_string_literal: true

module API
  module Entities
    class CommitWithLink < Commit
      include MarkupHelper
      include RequestAwareEntity

      expose :author, using: Entities::UserPath

      expose :author_gravatar_url do |commit|
        GravatarService.new.execute(commit.author_email)
      end

      expose :commit_url do |commit, options|
        project_commit_url(request.project, commit, params: options.fetch(:commit_url_params, {}))
      end

      expose :commit_path do |commit, options|
        project_commit_path(request.project, commit, params: options.fetch(:commit_url_params, {}))
      end

      expose :description_html, if: { type: :full } do |commit|
        markdown_field(commit, :description)
      end

      expose :title_html, if: { type: :full } do |commit|
        markdown_field(commit, :title)
      end

      expose :signature_html, if: { type: :full } do |commit|
        ::CommitPresenter.new(commit).signature_html
      end

      expose :prev_commit_id, if: { type: :full } do |commit|
        options[:prev_commit_id]
      end

      expose :next_commit_id, if: { type: :full } do |commit|
        options[:next_commit_id]
      end

      expose :pipeline_status_path, if: { type: :full } do |commit, options|
        pipeline_ref = options[:pipeline_ref]
        pipeline_project = options[:pipeline_project] || commit.project
        next unless pipeline_ref && pipeline_project

        pipeline = commit.latest_pipeline_for_project(pipeline_ref, pipeline_project)
        next unless pipeline&.status

        pipelines_project_commit_path(pipeline_project, commit.id, ref: pipeline_ref)
      end
    end
  end
end
