# == Schema Information
#
# Table name: ci_runners
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  description  :string(255)
#  contacted_at :datetime
#  active       :boolean          default(TRUE), not null
#  is_shared    :boolean          default(FALSE)
#  name         :string(255)
#  version      :string(255)
#  revision     :string(255)
#  platform     :string(255)
#  architecture :string(255)
#

module Ci
  class Runner < ActiveRecord::Base
    extend Ci::Model

    LAST_CONTACT_TIME = 5.minutes.ago
    AVAILABLE_SCOPES = ['specific', 'shared', 'active', 'paused', 'online']

    has_many :builds, class_name: 'Ci::Build'
    has_many :runner_projects, dependent: :destroy, class_name: 'Ci::RunnerProject'
    has_many :projects, through: :runner_projects, class_name: '::Project', foreign_key: :gl_project_id

    has_one :last_build, ->() { order('id DESC') }, class_name: 'Ci::Build'

    before_validation :set_default_values

    scope :specific, ->() { where(is_shared: false) }
    scope :shared, ->() { where(is_shared: true) }
    scope :active, ->() { where(active: true) }
    scope :paused, ->() { where(active: false) }
    scope :online, ->() { where('contacted_at > ?', LAST_CONTACT_TIME) }
    scope :ordered, ->() { order(id: :desc) }

    scope :owned_or_shared, ->(project_id) do
      joins('LEFT JOIN ci_runner_projects ON ci_runner_projects.runner_id = ci_runners.id')
        .where("ci_runner_projects.gl_project_id = :project_id OR ci_runners.is_shared = true", project_id: project_id)
    end

    acts_as_taggable

    # Searches for runners matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # This method performs a *partial* match on tokens, thus a query for "a"
    # will match any runner where the token contains the letter "a". As a result
    # you should *not* use this method for non-admin purposes as otherwise users
    # might be able to query a list of all runners.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def self.search(query)
      t = arel_table
      pattern = "%#{query}%"

      where(t[:token].matches(pattern).or(t[:description].matches(pattern)))
    end

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
    end

    def assign_to(project, current_user = nil)
      self.is_shared = false if shared?
      self.save
      project.runner_projects.create!(runner_id: self.id)
    end

    def display_name
      return short_sha unless !description.blank?

      description
    end

    def shared?
      is_shared
    end

    def online?
      contacted_at && contacted_at > LAST_CONTACT_TIME
    end

    def status
      if contacted_at.nil?
        :not_connected
      elsif active?
        online? ? :online : :offline
      else
        :paused
      end
    end

    def belongs_to_one_project?
      runner_projects.count == 1
    end

    def specific?
      !shared?
    end

    def only_for?(project)
      projects == [project]
    end

    def short_sha
      token[0...8] if token
    end
  end
end
