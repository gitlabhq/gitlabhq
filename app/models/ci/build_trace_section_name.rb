module Ci
  class BuildTraceSectionName < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :project
    has_many :trace_sections, class_name: 'Ci::BuildTraceSection', foreign_key: :section_name_id

    validates :name, :project, presence: true, allow_blank: false
    validates :name, uniqueness: { scope: :project_id }
  end
end
