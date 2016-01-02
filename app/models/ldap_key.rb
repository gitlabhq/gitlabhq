# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#  type       :string(255)
#

class LDAPKey < Key
end
