# frozen_string_literal: true

FactoryBot.define do
  factory :design_at_version, class: 'DesignManagement::DesignAtVersion' do
    skip_create # This is not an Active::Record model.

    design { nil }

    version { nil }

    transient do
      issue { design&.issue || version&.issue || association(:issue) }
    end

    initialize_with do
      attrs = attributes.dup
      attrs[:design] ||= association(:design, issue: issue)
      attrs[:version] ||= association(:design_version, issue: issue)

      new(**attrs)
    end
  end
end
