class Wiki < ActiveRecord::Base
  belongs_to :project

  validates :content, :title, :presence => true
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
