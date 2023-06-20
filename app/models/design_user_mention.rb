# frozen_string_literal: true

class DesignUserMention < UserMention
  include IgnorableColumns

  ignore_column :note_id_convert_to_bigint, remove_with: '16.2', remove_after: '2023-07-22'

  belongs_to :design, class_name: 'DesignManagement::Design'
  belongs_to :note
end
