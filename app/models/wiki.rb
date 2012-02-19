class Wiki < ActiveRecord::Base
  belongs_to :project

  validates :content, :title, :presence => true
  validates :title, :length => 1..250,
                    :uniqueness => {:scope => :project_id, :case_sensitive => false}

  before_save :set_slug


  def to_param
    slug
  end

  protected

  def set_slug
    self.slug = self.title.parameterize
  end
end
