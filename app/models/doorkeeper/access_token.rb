# frozen_string_literal: true

# Original file https://github.com/doorkeeper-gem/doorkeeper/blob/main/lib/doorkeeper/orm/active_record/access_token.rb

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  class AccessToken < ::ApplicationRecord
    include Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
    include SafelyChangeColumnDefault

    columns_changing_default :organization_id

    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
  end
end
