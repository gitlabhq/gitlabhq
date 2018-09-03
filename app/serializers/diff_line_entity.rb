# frozen_string_literal: true

class DiffLineEntity < Grape::Entity
  expose :line_code
  expose :type
  expose :old_line
  expose :new_line
  expose :text
  expose :meta_positions, as: :meta_data

  expose :rich_text do |line|
    line.rich_text || CGI.escapeHTML(line.text)
  end
end
