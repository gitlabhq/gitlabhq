# frozen_string_literal: true

class Review < ApplicationRecord
  include Participable
  include Mentionable

  belongs_to :author, class_name: 'User', foreign_key: :author_id, inverse_of: :reviews
  belongs_to :merge_request, inverse_of: :reviews
  belongs_to :project, inverse_of: :reviews

  has_many :notes, -> { order(:id) }, inverse_of: :review

  delegate :name, to: :author, prefix: true

  participant :author

  def all_references(current_user = nil, extractor: nil)
    ext = super

    notes.each do |note|
      note.all_references(current_user, extractor: ext)
    end

    ext
  end

  def user_mentions
    merge_request.user_mentions.where.not(note_id: nil)
  end
end
