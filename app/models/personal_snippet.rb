# == Schema Information
#
# Table name: snippets
#
#  id               :integer          not null, primary key
#  title            :string
#  content          :text
#  author_id        :integer          not null
#  project_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#  file_name        :string
#  type             :string
#  visibility_level :integer          default(0), not null
#

class PersonalSnippet < Snippet
end
