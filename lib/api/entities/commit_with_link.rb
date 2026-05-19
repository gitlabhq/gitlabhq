# frozen_string_literal: true

module API
  module Entities
    class CommitWithLink < Commit
      include MarkupHelper
      include RequestAwareEntity

      expose :author, using: ::API::Entities::UserPath, documentation: { type: '::API::Entities::UserPath' }

      expose :author_gravatar_url,
        documentation: { type: 'String', example: 'https://www.gravatar.com/avatar/abc' } do |commit|
        GravatarService.new.execute(commit.author_email)
      end

      expose :commit_url,
        documentation: { type: 'String',
                         example: 'https://gitlab.example.com/project/-/commit/abc' } do |commit, options|
        project_commit_url(request.project, commit, params: options.fetch(:commit_url_params, {}))
      end

      expose :commit_path, documentation: { type: 'String', example: '/project/-/commit/abc' } do |commit, options|
        project_commit_path(request.project, commit, params: options.fetch(:commit_url_params, {}))
      end

      expose :description_html,
        documentation: { type: 'String', example: '<p>description</p>' },
        if: { type: :full } do |commit|
        markdown_field(commit, :description)
      end

      expose :title_html,
        documentation: { type: 'String', example: '<p>title</p>' },
        if: { type: :full } do |commit|
        markdown_field(commit, :title)
      end

      expose :signature_html,
        documentation: { type: 'String', example: '<p>signature</p>' },
        if: { type: :full } do |commit|
        ::CommitPresenter.new(commit).signature_html
      end

      expose :prev_commit_id,
        documentation: { type: 'String', example: '2695effb5807a22ff3d138d593fd856244e155e7' },
        if: { type: :full } do |commit|
        options[:prev_commit_id]
      end

      expose :next_commit_id,
        documentation: { type: 'String', example: '2695effb5807a22ff3d138d593fd856244e155e7' },
        if: { type: :full } do |commit|
        options[:next_commit_id]
      end

      expose :pipeline_status_path,
        documentation: { type: 'String', example: '/project/pipelines/1' },
        if: { type: :full } do |commit, options|
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
