class Wiki < ActiveRecord::Base
  attr_accessible :title, :content, :slug

  belongs_to :project
  belongs_to :user
  has_many :notes, as: :noteable, dependent: :destroy

  validates :content, :title, :user_id, presence: true
  validates :title, length: 1..250

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

    # Scope with last revisions of pages (i.e. newest page per project_id
    # and slug).
    #
    # This is instead of Wiki.group(:slug).order(:created_at) which in this
    # case generates query violating SQL standard (thus doesn't work on PgSQL).
    #
    # return:
    #   ActiveRecord::Relation
    #
    def last_revisions
      t1 = arel_table.alias(table_name + '1')
      where(created_at: from(t1).select(t1[:created_at].maximum)
                                .where(project_id: t1[:project_id], slug: t1[:slug]))
    end
  end
end

# == Schema Information
#
# Table name: wikis
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  content    :text
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  slug       :string(255)
#  user_id    :integer
#
