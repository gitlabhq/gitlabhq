# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rendering json:table code block in markdown', :js, feature_category: :markdown do
  let_it_be(:project) { create(:project, :public) }

  it 'creates regular JSON table correctly' do
    description = <<~JSONTABLE
      Hello world!

      ```json:table
      {
        "fields" : [
            {"key": "a", "label": "AA"},
            {"key": "b", "label": "BB"}
        ],
        "items" : [
          {"a": "11", "b": "22"},
          {"a": "211", "b": "222"}
        ]
      }
      ```
    JSONTABLE

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests

    within ".js-json-table table" do
      headers = all("thead th").collect { |column| column.text.strip }
      data = all("tbody td").collect { |column| column.text.strip }

      expect(headers).to eql(%w[AA BB])
      expect(data).to eql(%w[11 22 211 222])
    end
  end

  it 'creates markdown JSON table correctly' do
    description = <<~JSONTABLE
      Hello world!

      ```json:table
      {
        "fields" : [
            {"key": "a", "label": "AA"},
            {"key": "b", "label": "BB"}
        ],
        "items" : [
          {"a": "11", "b": "22"},
          {"a": "211", "b": "222"}
        ],
        "markdown": true
      }
      ```
    JSONTABLE

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests

    within ".js-json-table table" do
      headers = all("thead th").collect { |column| column.text.strip }
      data = all("tbody td").collect { |column| column.text.strip }

      expect(headers).to eql(%w[AA BB])
      expect(data).to eql(%w[11 22 211 222])
    end
  end
end
