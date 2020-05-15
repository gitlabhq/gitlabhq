# frozen_string_literal: true

module API
  module Entities
    class Release < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name do |release, _|
        can_download_code? ? release.name : "Release-#{release.id}"
      end
      expose :tag, as: :tag_name, if: ->(_, _) { can_download_code? }
      expose :description
      expose :description_html do |entity|
        MarkupHelper.markdown_field(entity, :description, current_user: options[:current_user])
      end
      expose :created_at
      expose :released_at
      expose :author, using: Entities::UserBasic, if: -> (release, _) { release.author.present? }
      expose :commit, using: Entities::Commit, if: ->(_, _) { can_download_code? }
      expose :upcoming_release?, as: :upcoming_release
      expose :milestones, using: Entities::MilestoneWithStats, if: -> (release, _) { release.milestones.present? && can_read_milestone? }
      expose :commit_path, expose_nil: false
      expose :tag_path, expose_nil: false

      expose :assets do
        expose :assets_count, as: :count do |release, _|
          assets_to_exclude = can_download_code? ? [] : [:sources]
          release.assets_count(except: assets_to_exclude)
        end
        expose :sources, using: Entities::Releases::Source, if: ->(_, _) { can_download_code? }
        expose :links, using: Entities::Releases::Link do |release, options|
          release.links.sorted
        end
      end
      expose :evidences, using: Entities::Releases::Evidence, expose_nil: false, if: ->(_, _) { can_download_code? }
      expose :_links do
        expose :self_url, as: :self, expose_nil: false
        expose :merge_requests_url, expose_nil: false
        expose :issues_url, expose_nil: false
        expose :edit_url, expose_nil: false
      end

      private

      def can_download_code?
        Ability.allowed?(options[:current_user], :download_code, object.project)
      end

      def can_read_milestone?
        Ability.allowed?(options[:current_user], :read_milestone, object.project)
      end
    end
  end
end
