# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::CrmContactFilter do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be(:contact1) { create(:contact, group: group) }
  let_it_be(:contact2) { create(:contact, group: group) }

  let_it_be(:contact1_issue1) { create(:issue, project: project) }
  let_it_be(:contact1_issue2) { create(:issue, project: project) }
  let_it_be(:contact2_issue1) { create(:issue, project: project) }
  let_it_be(:issues) { Issue.where(id: [contact1_issue1.id, contact1_issue2.id, contact2_issue1.id]) }

  before_all do
    create(:issue_customer_relations_contact, issue: contact1_issue1, contact: contact1)
    create(:issue_customer_relations_contact, issue: contact1_issue2, contact: contact1)
    create(:issue_customer_relations_contact, issue: contact2_issue1, contact: contact2)
  end

  describe 'when a contact has issues' do
    it 'returns all contact1 issues' do
      params = { crm_contact_id: contact1.id }

      expect(described_class.new(params: params).filter(issues)).to contain_exactly(contact1_issue1, contact1_issue2)
    end

    it 'returns all contact2 issues' do
      params = { crm_contact_id: contact2.id }

      expect(described_class.new(params: params).filter(issues)).to contain_exactly(contact2_issue1)
    end
  end

  describe 'when a contact has no issues' do
    it 'returns no issues' do
      contact3 = create(:contact, group: group)
      params = { crm_contact_id: contact3.id }

      expect(described_class.new(params: params).filter(issues)).to be_empty
    end
  end
end
