class Wiki < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  validates :content, :title, :user_id, :presence => true
  validates :title, :length => 1..250

  before_update :set_slug

  def to_param
    slug
  end

  protected

  def set_slug
    self.slug = self.title.parameterize
  end

  class << self
    def regenerate_from wiki
      regenerated_field = [:slug, :content, :title]

      new_wiki = Wiki.new
      regenerated_field.each do |field|
        new_wiki.send("#{field}=", wiki.send(field))
      end
      new_wiki
    end

  end
end
# == Schema Information
#
# Table name: wikis
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  content    :text
#  project_id :integer(4)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  slug       :string(255)
#  user_id    :integer(4)
#

