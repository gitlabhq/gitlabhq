# frozen_string_literal: true

FactoryBot.define do
  factory :wiki do
    transient do
      container { association(:project, :wiki_repo) }
      user { association(:user) }
    end

    initialize_with { Wiki.for_container(container, user) }
    skip_create

    factory :project_wiki do
      transient do
        project { association(:project, :wiki_repo) }
      end

      container { project }
    end

    factory :group_wiki do
      container { association(:group, :wiki_repo) }
    end
  end
end
