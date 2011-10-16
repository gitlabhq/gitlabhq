class Snippet < ActiveRecord::Base
  belongs_to :project
  belongs_to :author, :class_name => "User"
  has_many :notes, :as => :noteable

  attr_protected :author, :author_id, :project, :project_id

  validates_presence_of :project_id
  validates_presence_of :author_id

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }
  
  validates :file_name,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :content,
            :presence => true,
            :length   => { :within => 0..10000 }


  def self.content_types
    [ 
      ".rb", ".py", ".pl", ".scala", ".c", ".cpp", ".java",
      ".haml", ".html", ".sass", ".scss", ".xml", ".php", ".erb",
      ".js", ".sh", ".coffee", ".yml", ".md"
    ]
  end
end
