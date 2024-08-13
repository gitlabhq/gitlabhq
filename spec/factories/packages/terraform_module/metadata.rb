# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_module_metadatum, class: 'Packages::TerraformModule::Metadatum' do
    package { association(:terraform_module_package) }
    project { package.project }
    fields { { root: { readme: 'README' }, submodules: { 'submodule1' => { readme: 'submodule1 README' } } } }
  end
end
