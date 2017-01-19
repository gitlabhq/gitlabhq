module RepositorySizeLimit
  extend ActiveSupport::Concern

  included do
    before_save :convert_from_megabytes_to_bytes, if: :repository_size_limit_changed?
  end

  private

  def convert_from_megabytes_to_bytes
    self.repository_size_limit = (repository_size_limit * 1.megabyte) if repository_size_limit.present?
  end
end
