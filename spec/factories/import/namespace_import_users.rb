# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_import_user, class: 'Import::NamespaceImportUser' do
    import_user factory: :user
    namespace
  end
end
