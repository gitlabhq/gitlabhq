# frozen_string_literal: true

class DesignUserMention < UserMention
  belongs_to :design, class_name: 'DesignManagement::Design'
  belongs_to :note
end
