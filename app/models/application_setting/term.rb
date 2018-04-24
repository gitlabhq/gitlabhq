class ApplicationSetting
  class Term < ActiveRecord::Base
    validates :terms, presence: true
  end
end
