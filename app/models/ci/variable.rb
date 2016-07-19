module Ci
  class Variable < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id

    validates_uniqueness_of :key, scope: :gl_project_id
    validates :key,
      presence: true,
      length: { within: 0..255 },
      format: { with: /\A[a-zA-Z0-9_]+\z/,
                message: "can contain only letters, digits and '_'." }

    attr_encrypted :value, 
       mode: :per_attribute_iv_and_salt,
       insecure_mode: true,
       key: Gitlab::Application.secrets.db_key_base,
       algorithm: 'aes-256-cbc'
  end
end
