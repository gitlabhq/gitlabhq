# == Schema Information
#
# Table name: runners
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
    
    has_many :builds, class_name: 'Ci::Build'
    has_many :runner_projects, dependent: :destroy, class_name: 'Ci::RunnerProject'
    has_many :projects, through: :runner_projects, class_name: 'Ci::Project'

    has_one :last_build, ->() { order('id DESC') }, class_name: 'Ci::Build'

    before_validation :set_default_values

    scope :specific, ->() { where(is_shared: false) }
    scope :shared, ->() { where(is_shared: true) }
    scope :active, ->() { where(active: true) }
    scope :paused, ->() { where(active: false) }

    acts_as_taggable

    def self.search(query)
      where('LOWER(ci_runners.token) LIKE :query OR LOWER(ci_runners.description) like :query',
            query: "%#{query.try(:downcase)}%")
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
      return token unless !description.blank?

      description
    end

    def shared?
      is_shared
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
      token[0...10]
    end
  end
end
