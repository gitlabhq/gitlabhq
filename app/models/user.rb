class User < ActiveRecord::Base

  include Account

  devise :database_authenticatable, :token_authenticatable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :bio,
                  :name, :projects_limit, :skype, :linkedin, :twitter, :dark_scheme,
                  :theme_id, :force_random_password, :extern_uid, :provider

  attr_accessor :force_random_password

  has_many :users_projects, dependent: :destroy
  has_many :projects, through: :users_projects
  has_many :my_own_projects, class_name: "Project", foreign_key: :owner_id
  has_many :keys, dependent: :destroy

  has_many :events,
    class_name: "Event",
    foreign_key: :author_id,
    dependent: :destroy

  has_many :recent_events,
    class_name: "Event",
    foreign_key: :author_id,
    order: "id DESC"

  has_many :issues,
    foreign_key: :author_id,
    dependent: :destroy

  has_many :notes,
    foreign_key: :author_id,
    dependent: :destroy

  has_many :assigned_issues,
    class_name: "Issue",
    foreign_key: :assignee_id,
    dependent: :destroy

  has_many :merge_requests,
    foreign_key: :author_id,
    dependent: :destroy

  has_many :assigned_merge_requests,
    class_name: "MergeRequest",
    foreign_key: :assignee_id,
    dependent: :destroy

  validates :projects_limit,
            presence: true,
            numericality: {greater_than_or_equal_to: 0}

  validates :bio, length: { within: 0..255 }

  validates :extern_uid, :allow_blank => true, :uniqueness => {:scope => :provider}

  before_save :ensure_authentication_token
  alias_attribute :private_token, :authentication_token

  scope :not_in_project, lambda { |project|  where("id not in (:ids)", ids: project.users.map(&:id) ) }
  scope :admins, where(admin:  true)
  scope :blocked, where(blocked:  true)
  scope :active, where(blocked:  false)

  before_validation :generate_password, on: :create

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end
  end

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

  def self.find_for_ldap_auth(auth, signed_in_resource=nil)
    uid = auth.info.uid
    provider = auth.provider
    name = auth.info.name.force_encoding("utf-8")
    email = auth.info.email.downcase unless auth.info.email.nil?
    raise OmniAuth::Error, "LDAP accounts must provide an uid and email address" if uid.nil? or email.nil?

    if @user = User.find_by_extern_uid_and_provider(uid, provider)
      @user
    # workaround for backward compatibility
    elsif @user = User.find_by_email(email)
      logger.info "Updating legacy LDAP user #{email} with extern_uid => #{uid}"
      @user.update_attributes(:extern_uid => uid, :provider => provider)
      @user
    else
      logger.info "Creating user from LDAP login {uid => #{uid}, name => #{name}, email => #{email}}"
      password = Devise.friendly_token[0, 8].downcase
      @user = User.create(
        :extern_uid => uid,
        :provider => provider,
        :name => name,
        :email => email,
        :password => password,
        :password_confirmation => password,
        :projects_limit => Gitlab.config.default_projects_limit
      )
    end
  end

  def self.search query
    where("name like :query or email like :query", query: "%#{query}%")
  end
end
# == Schema Information
#
# Table name: users
#
#  id                     :integer(4)      not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer(4)      default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  name                   :string(255)
#  admin                  :boolean(1)      default(FALSE), not null
#  projects_limit         :integer(4)      default(10)
#  skype                  :string(255)     default(""), not null
#  linkedin               :string(255)     default(""), not null
#  twitter                :string(255)     default(""), not null
#  authentication_token   :string(255)
#  dark_scheme            :boolean(1)      default(FALSE), not null
#  theme_id               :integer(4)      default(1), not null
#  bio                    :string(255)
#  blocked                :boolean(1)      default(FALSE), not null
#

