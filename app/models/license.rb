class License < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  validate :valid_license
  validate :active_user_count, if: :new_record?, unless: :validate_with_trueup?
  validate :check_trueup, unless: :persisted?, if: :validate_with_trueup?
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
    restricted_attr(:add_ons, {})
  end

  def add_on?(code)
    add_ons[code].to_i > 0
  end

  def restricted_user_count
    restricted_attr(:active_user_count)
  end

  def previous_user_count
    restricted_attr(:previous_user_count)
  end

  def validate_with_trueup?
    [restricted_attr(:trueup_quantity),
     restricted_attr(:trueup_from),
     restricted_attr(:trueup_to)].all?(&:present?)
  end

  private

  def restricted_attr(name, default = nil)
    return default unless license? && restricted?(name)

    restrictions[name]
  end

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

  def historical_max(from, to)
    HistoricalData.during(from..to).maximum(:active_user_count) || 0
  end

  def active_user_count
    return unless restricted_user_count

    historical_user_count = historical_max((starts_at - 1.year), starts_at)
    overage               = historical_user_count - restricted_user_count

    return if historical_user_count <= restricted_user_count

    add_limit_error(user_count: historical_user_count, restricted_user_count: restricted_user_count, overage: overage)
  end

  def check_trueup
    trueup_qty          = restrictions[:trueup_quantity]
    trueup_from         = Date.parse(restrictions[:trueup_from]) rescue (starts_at - 1.year)
    trueup_to           = Date.parse(restrictions[:trueup_to]) rescue starts_at
    active_user_count   = User.active.count
    max_historical      = historical_max(trueup_from, trueup_to)
    overage             = active_user_count - restricted_user_count
    expected_trueup_qty = if previous_user_count
                            max_historical - previous_user_count
                          else
                            max_historical - active_user_count
                          end

    if trueup_qty >= expected_trueup_qty
      if restricted_user_count < active_user_count
        add_limit_error(trueup: true, user_count: active_user_count, restricted_user_count: restricted_user_count, overage: overage)
      end
    else
      message = "You have applied a True-up for #{trueup_qty} #{"user".pluralize(trueup_qty)} "
      message << "but you need one for #{expected_trueup_qty} #{"user".pluralize(expected_trueup_qty)}. "
      message << "Please contact sales at renewals@gitlab.com"

      self.errors.add(:base, message)
    end
  end

  def add_limit_error(trueup: false, user_count:, restricted_user_count:, overage:)
    message =  trueup ? "This GitLab installation currently has " : "During the year before this license started, this GitLab installation had "
    message << "#{number_with_delimiter(user_count)} active #{"user".pluralize(user_count)}, "
    message << "exceeding this license's limit of #{number_with_delimiter(restricted_user_count)} by "
    message << "#{number_with_delimiter(overage)} #{"user".pluralize(overage)}. "
    message << "Please upload a license for at least "
    message << "#{number_with_delimiter(user_count)} #{"user".pluralize(user_count)} or contact sales at renewals@gitlab.com"

    self.errors.add(:base, message)
  end

  def not_expired
    return unless self.license? && self.expired?

    self.errors.add(:base, "This license has already expired.")
  end
end
