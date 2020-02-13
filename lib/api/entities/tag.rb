# frozen_string_literal: true

module API
  module Entities
    class Tag < Grape::Entity
      expose :name, :message, :target

      expose :commit, using: Entities::Commit do |repo_tag, options|
        options[:project].repository.commit(repo_tag.dereferenced_target)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      expose :release, using: Entities::TagRelease do |repo_tag, options|
        options[:project].releases.find_by(tag: repo_tag.name)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      expose :protected do |repo_tag, options|
        ::ProtectedTag.protected?(options[:project], repo_tag.name)
      end
    end
  end
end
