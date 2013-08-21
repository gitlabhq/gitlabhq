# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text(2147483647)
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  file_name  :string(255)
#  expires_at :datetime
#  private    :boolean          default(TRUE), not null
#  type       :string(255)
#

class PersonalSnippet < Snippet
end
