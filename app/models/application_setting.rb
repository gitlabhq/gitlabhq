# == Schema Information
#
# Table name: application_settings
#
#  id                     :integer          not null, primary key
#  default_projects_limit :integer
#  default_branch_protection :integer
#  signup_enabled         :boolean
#  signin_enabled         :boolean
#  gravatar_enabled       :boolean
#  twitter_sharing_enabled  :boolean
#  sign_in_text           :text
#  created_at             :datetime
#  updated_at             :datetime
#  home_page_url          :string(255)
#

class ApplicationSetting < ActiveRecord::Base
  validates :home_page_url,
    allow_blank: true,
    format: { with: URI::regexp(%w(http https)), message: "should be a valid url" },
    if: :home_page_url_column_exist

  def self.current
    ApplicationSetting.last
  end

  def self.create_from_defaults
    create(
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      default_branch_protection: Settings.gitlab['default_branch_protection'],
      signup_enabled: Settings.gitlab['signup_enabled'],
      signin_enabled: Settings.gitlab['signin_enabled'],
      twitter_sharing_enabled: Settings.gitlab['twitter_sharing_enabled'],
      gravatar_enabled: Settings.gravatar['enabled'],
      sign_in_text: Settings.extra['sign_in_text'],
    )
  end

  def home_page_url_column_exist
    ActiveRecord::Base.connection.column_exists?(:application_settings, :home_page_url)
  end
end
