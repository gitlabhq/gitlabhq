# frozen_string_literal: true

FactoryBot.define do
  factory :package_protection_rule, class: 'Packages::Protection::Rule' do
    project
    package_name_pattern { '@my_scope/my_package' }
    package_type { :npm }
    minimum_access_level_for_delete { :owner }
    minimum_access_level_for_push { :maintainer }
    pattern { '@my_scope/my_package' }
    pattern_type { :wildcard }
    target_field { :package_name }
  end
end
