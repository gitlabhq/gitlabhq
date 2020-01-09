# frozen_string_literal: true

FactoryBot.define do
  factory :gitaly_tag, class: 'Gitaly::Tag' do
    skip_create

    name { 'v3.1.4' }
    message { 'Pie release' }
    target_commit factory: :gitaly_commit
  end
end
