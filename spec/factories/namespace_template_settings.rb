# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_template_setting, class: 'Namespaces::TemplateSetting' do
    namespace { association(:group) }
  end
end
