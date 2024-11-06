# frozen_string_literal: true

module API
  class Topics < ::API::Base
    include PaginationParams

    feature_category :groups_and_projects

    before do
      set_current_organization
    end

    helpers do
      def find_topic!(id)
        topic = ::Projects::Topic.find(id)

        find_organization!(topic.organization_id)

        topic
      end
    end

    desc 'Get topics' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      optional :search, type: String,
        desc: 'Return list of topics matching the search criteria',
        documentation: { example: 'search' }
      optional :without_projects, type: Boolean, desc: 'Return list of topics without assigned projects'
      optional :organization_id, type: Integer, default: -> { ::Current.organization_id },
        desc: 'The organization id for the topics'
      use :pagination
    end
    get 'topics' do
      organization = find_organization!(params[:organization_id])

      topics = ::Projects::TopicsFinder.new(
        params: declared_params(include_missing: false),
        organization_id: organization.id
      ).execute

      present paginate(topics), with: Entities::Projects::Topic
    end

    desc 'Get topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :id, type: Integer, desc: 'ID of project topic'
    end
    get 'topics/:id' do
      topic = find_topic!(params[:id])

      present topic, with: Entities::Projects::Topic
    end

    desc 'Create a topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :name, type: String, desc: 'Slug (name)'
      requires :title, type: String, desc: 'Title'
      optional :description, type: String, desc: 'Description'
      optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for topic',
        documentation: { type: 'file' }
      optional :organization_id, type: Integer, default: -> { ::Current.organization_id },
        desc: 'The organization id for the topic'
    end
    post 'topics' do
      authenticated_as_admin!

      find_organization!(params[:organization_id]) if params[:organization_id].present?
      topic = ::Projects::Topic.new(declared_params(include_missing: false))

      if topic.save
        present topic, with: Entities::Projects::Topic
      else
        render_validation_error!(topic)
      end
    end

    desc 'Update a topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :id, type: Integer, desc: 'ID of project topic'
      optional :name, type: String, desc: 'Slug (name)'
      optional :title, type: String, desc: 'Title'
      optional :description, type: String, desc: 'Description'
      optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for topic',
        documentation: { type: 'file' }
    end
    put 'topics/:id' do
      authenticated_as_admin!

      topic = find_topic!(params[:id])

      topic.remove_avatar! if params.key?(:avatar) && params[:avatar].nil?

      if topic.update(declared_params(include_missing: false))
        present topic, with: Entities::Projects::Topic
      else
        render_validation_error!(topic)
      end
    end

    desc 'Delete a topic' do
      detail 'This feature was introduced in GitLab 14.9.'
    end
    params do
      requires :id, type: Integer, desc: 'ID of project topic'
    end
    delete 'topics/:id' do
      authenticated_as_admin!

      topic = find_topic!(params[:id])

      destroy_conditionally!(topic)
    end

    desc 'Merge topics' do
      detail 'This feature was introduced in GitLab 15.4.'
      success Entities::Projects::Topic
    end
    params do
      requires :source_topic_id, type: Integer, desc: 'ID of source project topic'
      requires :target_topic_id, type: Integer, desc: 'ID of target project topic'
    end
    post 'topics/merge' do
      authenticated_as_admin!

      source_topic = find_topic!(params[:source_topic_id])
      target_topic = find_topic!(params[:target_topic_id])

      response = ::Topics::MergeService.new(source_topic, target_topic).execute
      render_api_error!(response.message, :bad_request) if response.error?

      present target_topic, with: Entities::Projects::Topic
    end
  end
end
