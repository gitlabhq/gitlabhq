class PersonalSnippet < Snippet
  # Elastic search configuration (it does not support STI)
  document_type 'snippet'
  index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
  include Elastic::SnippetsSearch
  include WithUploads
end
