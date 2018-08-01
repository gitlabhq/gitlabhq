class ProgrammingLanguage < ActiveRecord::Base
  validates :name, presence: true
  validates :color, allow_blank: false, color: true
end
