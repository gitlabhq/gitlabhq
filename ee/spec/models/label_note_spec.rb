# frozen_string_literal: true

require 'spec_helper'

describe LabelNote do
  set(:group)  { create(:group) }
  set(:user)   { create(:user) }
  set(:label) { create(:group_label, group: group) }
  set(:label2) { create(:group_label, group: group) }
  let(:resource_parent) { group }

  context 'when resource is epic' do
    set(:resource) { create(:epic, group: group) }
    let(:project) { nil }

    it_behaves_like 'label note created from events'
  end
end
