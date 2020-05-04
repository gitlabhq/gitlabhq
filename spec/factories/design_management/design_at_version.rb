# frozen_string_literal: true

FactoryBot.define do
  factory :design_at_version, class: 'DesignManagement::DesignAtVersion' do
    skip_create # This is not an Active::Record model.

    design { nil }

    version { nil }

    transient do
      issue { design&.issue || version&.issue || create(:issue) }
    end

    initialize_with do
      attrs = attributes.dup
      attrs[:design] ||= create(:design, issue: issue)
      attrs[:version] ||= create(:design_version, issue: issue)

      new(attrs)
    end
  end
end
