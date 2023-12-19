# frozen_string_literal: true

# Allow legacy usage of STI in models.
#
# The use of STI is disallowed otherwise and checked via
# `spec/support/shared_examples/models/disable_sti_shared_examples.rb`.
#
# See https://docs.gitlab.com/ee/development/database/single_table_inheritance.html
module DisablesSti
  extend ActiveSupport::Concern

  included do
    class_attribute :allow_legacy_sti_class
  end
end
