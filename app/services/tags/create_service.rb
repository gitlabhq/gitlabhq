# frozen_string_literal: true

module Tags
  class CreateService < BaseService
    def execute(tag_name, target, message)
      return error('Target is empty', 400) if target.blank?

      valid_tag = Gitlab::GitRefValidator.validate(tag_name)
      return error('Tag name invalid', 400) unless valid_tag

      repository = project.repository
      message = message&.strip

      new_tag = nil

      begin
        new_tag = repository.add_tag(current_user, tag_name, target, message)
      rescue Gitlab::Git::Repository::TagExistsError
        return error("Tag #{tag_name} already exists", 409)
      rescue Gitlab::Git::PreReceiveError => ex
        return error(ex.message)
      end

      if new_tag
        repository.expire_tags_cache

        success.merge(tag: new_tag)
      else
        error("Target #{target} is invalid", 400)
      end
    end
  end
end
