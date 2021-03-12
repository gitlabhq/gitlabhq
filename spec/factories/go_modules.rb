# frozen_string_literal: true

FactoryBot.define do
  factory :go_module, class: 'Packages::Go::Module' do
    initialize_with { new(attributes[:project], attributes[:name], attributes[:path]) }
    skip_create

    project { association(:project, :repository) }

    path { '' }
    name { "#{Settings.build_gitlab_go_url}/#{project.full_path}#{path.empty? ? '' : '/'}#{path}" }
  end
end
