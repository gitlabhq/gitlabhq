class License < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  validate :valid_license
  validate :active_user_count, unless: :persisted?
  validate :not_expired, unless: :persisted?

  before_validation :reset_license, if: :data_changed?

  after_create :reset_current
  after_destroy :reset_current

  scope :previous, -> { order(created_at: :desc).offset(1) }

  class << self
    def current
      if RequestStore.active?
        RequestStore.fetch(:current_license) { load_license }
      else
        load_license
      end
    end

    def reset_current
      RequestStore.delete(:current_license)
    end

    def block_changes?
      !current || current.block_changes?
    end

    def load_license
      license = self.last

      return unless license && license.valid?
      license
    end
  end

  def data_filename
    company_name = self.licensee["Company"] || self.licensee.values.first
    clean_company_name = company_name.gsub(/[^A-Za-z0-9]/, "")
    "#{clean_company_name}.gitlab-license"
  end

  def data_file=(file)
    self.data = file.read
  end

  def license
    return nil unless self.data

    @license ||=
      begin
        Gitlab::License.import(self.data)
      rescue Gitlab::License::ImportError
        nil
      end
  end

  def license?
    self.license && self.license.valid?
  end

  def method_missing(method_name, *arguments, &block)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      license.send(method_name, *arguments, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    if License.column_names.include?(method_name.to_s)
      super
    elsif license && license.respond_to?(method_name)
      true
    else
      super
    end
  end

  def add_ons
    return {} unless license? && restricted?(:add_ons)

    restrictions[:add_ons]
  end

  def add_on?(code)
    add_ons[code].to_i > 0
  end

  def user_count
    return unless self.license? && self.restricted?(:active_user_count)

    self.restrictions[:active_user_count]
  end

  private

  def reset_current
    self.class.reset_current
  end

  def reset_license
    @license = nil
  end

  def valid_license
    return if license?

    self.errors.add(:base, "The license key is invalid. Make sure it is exactly as you received it from GitLab Inc.")
  end

  def active_user_count
    restricted_user_count = user_count

    return unless restricted_user_count

    date_range = (self.starts_at - 1.year)..self.starts_at
    active_user_count = HistoricalData.during(date_range).maximum(:active_user_count) || 0

    return unless active_user_count

    return if active_user_count <= restricted_user_count

    overage = active_user_count - restricted_user_count

    message = ""
    message << "During the year before this license started, this GitLab installation had "
    message << "#{number_with_delimiter active_user_count} active #{"user".pluralize(active_user_count)}, "
    message << "exceeding this license's limit of #{number_with_delimiter restricted_user_count} by "
    message << "#{number_with_delimiter overage} #{"user".pluralize(overage)}. "
    message << "Please upload a license for at least "
    message << "#{number_with_delimiter active_user_count} #{"user".pluralize(active_user_count)}."

    self.errors.add(:base, message)
  end

  def not_expired
    return unless self.license? && self.expired?

    self.errors.add(:base, "This license has already expired.")
  end
end
