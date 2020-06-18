# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLabelsFinder, '#execute' do
  let!(:group) { create(:group) }
  let!(:user)  { create(:user) }
  let!(:label1) { create(:group_label, title: 'Foo', description: 'Lorem ipsum', group: group) }
  let!(:label2) { create(:group_label, title: 'Bar', description: 'Fusce consequat', group: group) }

  it 'returns all group labels sorted by name if no params' do
    result = described_class.new(user, group).execute

    expect(result.to_a).to match_array([label2, label1])
  end

  it 'returns all group labels sorted by name desc' do
    result = described_class.new(user, group, sort: 'name_desc').execute

    expect(result.to_a).to match_array([label2, label1])
  end

  it 'returns group labels that match search' do
    result = described_class.new(user, group, search: 'Foo').execute

    expect(result.to_a).to match_array([label1])
  end

  it 'returns group labels user subscribed to' do
    label2.subscribe(user)

    result = described_class.new(user, group, subscribed: 'true').execute

    expect(result.to_a).to match_array([label2])
  end

  it 'returns second page of labels' do
    result = described_class.new(user, group, page: '2').execute

    expect(result.to_a).to match_array([])
  end
end
