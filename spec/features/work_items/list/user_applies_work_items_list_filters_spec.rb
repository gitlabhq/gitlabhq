# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work items list filters', :js, feature_category: :planning_views do
  include FilteredSearchHelpers

  let_it_be(:user1, freeze: false) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, freeze: false) { create(:project, :public, group: group, developers: [user1]) }
  let_it_be(:label1, freeze: false) { create(:label, project: project) }

  let_it_be(:incident) do
    create(:incident, project: project,
      assignees: [user1],
      author: user1,
      description: 'aaa',
      labels: [label1])
  end

  describe 'customer relations organization' do
    let_it_be(:crm_organization1) { create(:crm_organization, group: group, name: 'GitLab Inc') }
    let_it_be(:crm_organization2) { create(:crm_organization, group: group, name: 'Acme Corp') }

    # Create contacts belonging to organizations
    let_it_be(:contact1) { create(:contact, group: group, organization: crm_organization1) }
    let_it_be(:contact2) { create(:contact, group: group, organization: crm_organization1) }
    let_it_be(:contact3) { create(:contact, group: group, organization: crm_organization2) }

    # Create issues and relate them to contacts (which belong to organizations)
    let_it_be(:org1_issue1) { create(:issue, project: project, title: 'GitLab Issue 1') }
    let_it_be(:org1_issue2) { create(:issue, project: project, title: 'GitLab Issue 2') }
    let_it_be(:org2_issue) { create(:issue, project: project, title: 'Acme Issue') }

    # Create the relationships between issues and contacts
    let_it_be(:issue_contact1) { create(:issue_customer_relations_contact, issue: org1_issue1, contact: contact1) }
    let_it_be(:issue_contact2) { create(:issue_customer_relations_contact, issue: org1_issue2, contact: contact2) }
    let_it_be(:issue_contact3) { create(:issue_customer_relations_contact, issue: org2_issue, contact: contact3) }

    shared_examples 'filters by CRM organization' do
      it 'filters by CRM organization', :aggregate_failures do
        # Organization just supports is operator so no need for passing '='
        select_tokens 'Organization', crm_organization1.name, submit: true

        expect(page).to have_css('.issue', count: 2)
        expect(page).to have_link(org1_issue1.title)
        expect(page).to have_link(org1_issue2.title)

        click_button 'Clear'
        expect(page).to have_link(incident.title)

        select_tokens 'Organization', crm_organization2.name, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(org2_issue.title)
      end
    end

    shared_examples 'filters by CRM contacts' do
      it 'filters by CRM contacts', :aggregate_failures do
        # Contact just supports `is` operator so no need for passing '='
        select_tokens 'Contact', contact1.first_name, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(org1_issue1.title)

        click_button 'Clear'
        expect(page).to have_link(incident.title)

        select_tokens 'Contact', contact2.first_name, submit: true

        expect(page).to have_css('.issue', count: 1)
        expect(page).to have_link(org1_issue2.title)
      end
    end

    before_all do
      group.add_developer(user1)
    end

    before do
      allow(user1).to receive_messages(read_crm_contact: true, read_crm_organization: true)

      sign_in(user1)
    end

    context 'when user is on group work items page' do
      before do
        visit group_work_items_path(group)
      end

      include_examples 'filters by CRM organization'
      include_examples 'filters by CRM contacts'
    end

    context 'when user is on work items page' do
      before do
        visit project_work_items_path(project)
      end

      include_examples 'filters by CRM organization'
      include_examples 'filters by CRM contacts'
    end
  end
end
