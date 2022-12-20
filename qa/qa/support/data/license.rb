# frozen_string_literal: true

module QA
  module Support
    module Data
      module License
        def license_user
          'GitLab QA'
        end

        def license_company
          'QA User'
        end

        def license_user_count
          10_000
        end

        def license_plan
          QA::ULTIMATE_SELF_MANAGED
        end
      end
    end
  end
end

QA::Support::Data::License.prepend_mod_with('Support::Data::License', namespace: QA)
