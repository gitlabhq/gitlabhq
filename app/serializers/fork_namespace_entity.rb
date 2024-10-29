# frozen_string_literal: true

class ForkNamespaceEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity
  include MarkupHelper

  expose :id, :name, :description, :visibility, :full_name,
    :created_at, :updated_at, :avatar_url

  expose :fork_path do |namespace, options|
    project_forks_path(options[:project], namespace_key: namespace.id)
  end

  expose :forked_project_path do |namespace, options|
    if forked_project = options.dig(:forked_projects, namespace.id)
      project_path(forked_project)
    end
  end

  expose :permission do |namespace, options|
    membership(options[:current_user], namespace, options[:memberships])&.human_access
  end

  expose :relative_path do |namespace|
    group_path(namespace)
  end

  expose :markdown_description do |namespace|
    markdown_description(namespace)
  end

  private

  def membership(user, object, memberships)
    return unless user

    memberships[object.id]
  end

  def markdown_description(namespace)
    markdown_field(namespace, :description)
  end
end

ForkNamespaceEntity.prepend_mod_with('ForkNamespaceEntity')
