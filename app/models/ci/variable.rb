module Ci
  class Variable < ActiveRecord::Base
    extend Ci::Model

    belongs_to :project

    validates :key,
      presence: true,
      uniqueness: { scope: :project_id },
      length: { maximum: 255 },
      format: { with: /\A[a-zA-Z0-9_]+\z/,
                message: "can contain only letters, digits and '_'." }

    scope :order_key_asc, -> { reorder(key: :asc) }
    scope :unprotected, -> { where(protected: false) }

    attr_encrypted :value,
       mode: :per_attribute_iv_and_salt,
       insecure_mode: true,
       key: Gitlab::Application.secrets.db_key_base,
       algorithm: 'aes-256-cbc'

    def to_runner_variable
      { key: key, value: value, public: false }
    end
  end
end
