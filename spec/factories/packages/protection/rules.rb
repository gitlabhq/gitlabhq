# frozen_string_literal: true

FactoryBot.define do
  factory :package_protection_rule, class: 'Packages::Protection::Rule' do
    project
    package_name_pattern { '@my_scope/my_package' }
    package_type { :npm }
    push_protected_up_to_access_level { :developer }
  end
end
