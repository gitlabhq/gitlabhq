class User < ActiveRecord::Base
  include Account

  devise :database_authenticatable, :token_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :bio,
                  :name, :projects_limit, :skype, :linkedin, :twitter, :dark_scheme, :theme_id

  has_many :users_projects, :dependent => :destroy
  has_many :projects, :through => :users_projects
  has_many :my_own_projects, :class_name => "Project", :foreign_key => :owner_id
  has_many :keys, :dependent => :destroy

  has_many :recent_events,
    :class_name => "Event",
    :foreign_key => :author_id,
    :order => "id DESC"

  has_many :issues,
    :foreign_key => :author_id,
    :dependent => :destroy

  has_many :notes,
    :foreign_key => :author_id,
    :dependent => :destroy

  has_many :assigned_issues,
    :class_name => "Issue",
    :foreign_key => :assignee_id,
    :dependent => :destroy

  has_many :merge_requests,
    :foreign_key => :author_id,
    :dependent => :destroy

  has_many :assigned_merge_requests,
    :class_name => "MergeRequest",
    :foreign_key => :assignee_id,
    :dependent => :destroy

  validates :projects_limit,
            :presence => true,
            :numericality => {:greater_than_or_equal_to => 0}

  validates :bio, :length => { :within => 0..255 }

  before_save :ensure_authentication_token
  alias_attribute :private_token, :authentication_token

  scope :not_in_project, lambda { |project|  where("id not in (:ids)", :ids => project.users.map(&:id) ) }
  scope :admins, where(:admin =>  true)
  scope :blocked, where(:blocked =>  true)
  scope :active, where(:blocked =>  false)

  def self.filter filter_name
    case filter_name
    when "admins"; self.admins
    when "blocked"; self.blocked
    when "wop"; self.without_projects
    else
      self.active
    end
  end

  def self.without_projects
    where('id NOT IN (SELECT DISTINCT(user_id) FROM users_projects)')
  end

  def self.find_for_ldap_auth(omniauth_info)
    name = omniauth_info.name.force_encoding("utf-8")
    email = omniauth_info.email.downcase

    if @user = User.find_by_email(email)
      @user
    else
      password = Devise.friendly_token[0, 8].downcase
      @user = User.create(
        :name => name,
        :email => email,
        :password => password,
        :password_confirmation => password
      )
    end
  end
end
# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  name                   :string(255)
#  admin                  :boolean         default(FALSE), not null
#  projects_limit         :integer         default(10)
#  skype                  :string(255)     default(""), not null
#  linkedin               :string(255)     default(""), not null
#  twitter                :string(255)     default(""), not null
#  authentication_token   :string(255)
#  dark_scheme            :boolean         default(FALSE), not null
#
