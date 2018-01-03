module HasVariable
  extend ActiveSupport::Concern

  included do
    validates :key,
      presence: true,
      length: { maximum: 255 },
      format: { with: /\A[a-zA-Z0-9_]+\z/,
                message: "can contain only letters, digits and '_'." }

    scope :order_key_asc, -> { reorder(key: :asc) }

    attr_encrypted :value,
       mode: :per_attribute_iv_and_salt,
       insecure_mode: true,
       key: Gitlab::Application.secrets.db_key_base,
       algorithm: 'aes-256-cbc'

    def key=(new_key)
      super(new_key.to_s.strip)
    end

    def to_runner_variable
      { key: key, value: value, public: false }
    end
  end
end
