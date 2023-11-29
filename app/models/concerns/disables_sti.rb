# frozen_string_literal: true

# Disables usage of STI
# See https://docs.gitlab.com/ee/development/database/single_table_inheritance.html
module DisablesSti
  extend ActiveSupport::Concern

  SKIP_STI_CHECK = !Gitlab.dev_or_test_env? ||
    Gitlab::Utils.to_boolean(ENV['SKIP_STI_CHECK'], default: false)

  included do
    class_attribute :allow_legacy_sti_class
  end

  class_methods do
    def new(...)
      if sti_class_disallowed?
        raise(
          "Do not use Single Table Inheritance (`#{name}` inherits `#{base_class.name}`). " \
          "See https://docs.gitlab.com/ee/development/database/single_table_inheritance.html" # rubocop:disable Gitlab/DocUrl -- route helpers don't always work
        )
      end

      super
    end

    def sti_class_disallowed?
      return false if SKIP_STI_CHECK

      self != base_class && !allow_legacy_sti_class && has_attribute?(inheritance_column)
    end
  end
end
