# == Schema Information
#
# Table name: snippets
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  content          :text
#  author_id        :integer          not null
#  project_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#  file_name        :string(255)
#  type             :string(255)
#  visibility_level :integer          default(0), not null
#

class PersonalSnippet < Snippet
  # Elastic search configuration (it does not support STI)
  document_type 'snippet'
  index_name [Rails.application.class.parent_name.downcase, 'snippet', Rails.env].join('-')
  include Elastic::SnippetsSearch
end
