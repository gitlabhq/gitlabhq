class NoteTemplate < ActiveRecord::Base
  belongs_to :user
  validates :user, :note, :title, presence: true
end
