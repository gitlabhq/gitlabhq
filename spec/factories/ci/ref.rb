# frozen_string_literal: true

FactoryBot.define do
  factory :ci_ref, class: 'Ci::Ref' do
    ref_path { 'refs/heads/master' }
    project
  end
end
