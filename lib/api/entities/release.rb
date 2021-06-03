# frozen_string_literal: true

module API
  module Entities
    class Release < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name
      expose :tag, as: :tag_name, if: ->(_, _) { can_download_code? }
      expose :description
      expose :description_html, if: -> (_, options) { options[:include_html_description] } do |entity|
        MarkupHelper.markdown_field(entity, :description, current_user: options[:current_user])
      end
      expose :created_at
      expose :released_at
      expose :author, using: Entities::UserBasic, if: -> (release, _) { release.author.present? }
      expose :commit, using: Entities::Commit, if: ->(_, _) { can_download_code? }
      expose :upcoming_release?, as: :upcoming_release
      expose :milestones,
             using: Entities::MilestoneWithStats,
             if: -> (release, _) { release.milestones.present? && can_read_milestone? } do |release, _|
               release.milestones.order_by_dates_and_title
             end

      expose :commit_path, expose_nil: false
      expose :tag_path, expose_nil: false

      expose :assets do
        expose :assets_count, as: :count
        expose :sources, using: Entities::Releases::Source, if: ->(_, _) { can_download_code? }
        expose :sorted_links, as: :links, using: Entities::Releases::Link
      end
      expose :evidences, using: Entities::Releases::Evidence, expose_nil: false, if: ->(_, _) { can_download_code? }
      expose :_links do
        expose :self_url, as: :self, expose_nil: false
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
