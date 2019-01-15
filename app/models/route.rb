# frozen_string_literal: true

class Route < ApplicationRecord
  include CaseSensitivity

  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  validates :source, presence: true

  validates :path,
    length: { within: 1..255 },
    presence: true,
    uniqueness: { case_sensitive: false }

  before_validation :delete_conflicting_orphaned_routes
  after_create :delete_conflicting_redirects
  after_update :delete_conflicting_redirects, if: :saved_change_to_path?
  after_update :create_redirect_for_old_path
  after_update :rename_descendants

  scope :inside_path, -> (path) { where('routes.path LIKE ?', "#{sanitize_sql_like(path)}/%") }

  def rename_descendants
    return unless saved_change_to_path? || saved_change_to_name?

    descendant_routes = self.class.inside_path(path_before_last_save)

    descendant_routes.each do |route|
      attributes = {}

      if saved_change_to_path? && route.path.present?
        attributes[:path] = route.path.sub(path_before_last_save, path)
      end

      if saved_change_to_name? && name_before_last_save.present? && route.name.present?
        attributes[:name] = route.name.sub(name_before_last_save, name)
      end

      if attributes.present?
        old_path = route.path

        # Callbacks must be run manually
        route.update_columns(attributes.merge(updated_at: Time.now))

        # We are not calling route.delete_conflicting_redirects here, in hopes
        # of avoiding deadlocks. The parent (self, in this method) already
        # called it, which deletes conflicts for all descendants.
        route.create_redirect(old_path) if attributes[:path]
      end
    end
  end

  def delete_conflicting_redirects
    conflicting_redirects.delete_all
  end

  def conflicting_redirects
    RedirectRoute.matching_path_and_descendants(path)
  end

  def create_redirect(path)
    RedirectRoute.create(source: source, path: path)
  end

  private

  def create_redirect_for_old_path
    create_redirect(path_before_last_save) if saved_change_to_path?
  end

  def delete_conflicting_orphaned_routes
    conflicting = self.class.iwhere(path: path)
    conflicting_orphaned_routes = conflicting.select do |route|
      route.source.nil?
    end

    conflicting_orphaned_routes.each(&:destroy)
  end
end
