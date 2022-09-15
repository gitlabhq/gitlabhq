# frozen_string_literal: true

FactoryBot.define do
  factory :rpm_metadatum, class: 'Packages::Rpm::Metadatum' do
    package { association(:rpm_package) }
    release { "#{rand(10)}.#{rand(10)}" }
    summary { FFaker::Lorem.sentences(2).join }
    description { FFaker::Lorem.sentences(4).join }
    arch { FFaker::Lorem.word }
    epoch { 0 }
  end
end
