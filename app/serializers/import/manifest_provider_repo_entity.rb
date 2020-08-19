# frozen_string_literal: true

class Import::ManifestProviderRepoEntity < Import::BaseProviderRepoEntity
  expose :id
  expose :full_name, override: true do |repo|
    repo[:url]
  end

  expose :provider_link, override: true do |repo|
    repo[:url]
  end

  expose :target do |repo, options|
    import_project_target(options[:group_full_path], repo[:path], options[:request].current_user)
  end

  private

  def import_project_target(owner, name, user)
    namespace = user.can_create_group? ? owner : user.namespace_path
    "#{namespace}/#{name}"
  end
end
