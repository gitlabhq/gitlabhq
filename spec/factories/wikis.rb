# frozen_string_literal: true

FactoryBot.define do
  factory :wiki do
    transient do
      container { association(:project) }
      user { container.default_owner || association(:user) }
    end

    initialize_with { Wiki.for_container(container, user) }
    skip_create

    factory :project_wiki do
      transient do
        project { association(:project) }
      end

      container { project }
    end
  end
end
