module Ci
  class Variable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable
<<<<<<< HEAD
    prepend EE::Ci::Variable
=======
    include Presentable
>>>>>>> master-ce

    belongs_to :project

    validates :key, uniqueness: { scope: [:project_id, :environment_scope] }

    scope :unprotected, -> { where(protected: false) }
  end
end
