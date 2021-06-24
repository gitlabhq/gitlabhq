# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequests, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include WikiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }

  let_it_be(:project_wiki) { create(:project_wiki, user: user) }

  let(:project_wiki_page) { create(:wiki_page, wiki: project_wiki) }

  fixture_subdir = 'api/markdown'

  before(:all) do
    clean_frontend_fixtures(fixture_subdir)

    group.add_owner(user)
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  markdown_examples = begin
    yaml_file_path = File.expand_path('api_markdown.yml', __dir__)
    yaml = File.read(yaml_file_path)
    YAML.safe_load(yaml, symbolize_names: true)
  end

  markdown_examples.each do |markdown_example|
    context = markdown_example.fetch(:context, '')
    name = markdown_example.fetch(:name)

    context "for #{name}#{!context.empty? ? " (context: #{context})" : ''}" do
      let(:markdown) { markdown_example.fetch(:markdown) }

      name = "#{context}_#{name}" unless context.empty?

      it "#{fixture_subdir}/#{name}.json" do
        api_url = case context
                  when 'project'
                    "/#{project.full_path}/preview_markdown"
                  when 'group'
                    "/groups/#{group.full_path}/preview_markdown"
                  when 'project_wiki'
                    "/#{project.full_path}/-/wikis/#{project_wiki_page.slug}/preview_markdown"
                  else
                    api "/markdown"
                  end

        post api_url, params: { text: markdown, gfm: true }
        expect(response).to be_successful
      end
    end
  end
end
