# frozen_string_literal: true

require 'spec_helper'

describe GroupLabelsFinder, '#execute' do
  let!(:group) { create(:group) }
  let!(:label1) { create(:group_label, title: 'Foo', description: 'Lorem ipsum', group: group) }
  let!(:label2) { create(:group_label, title: 'Bar', description: 'Fusce consequat', group: group) }

  it 'returns all group labels sorted by name if no params' do
    result = described_class.new(group).execute

    expect(result.to_a).to match_array([label2, label1])
  end

  it 'returns all group labels sorted by name desc' do
    result = described_class.new(group, sort: 'name_desc').execute

    expect(result.to_a).to match_array([label2, label1])
  end

  it 'returns group labels that march search' do
    result = described_class.new(group, search: 'Foo').execute

    expect(result.to_a).to match_array([label1])
  end

  it 'returns second page of labels' do
    result = described_class.new(group, page: '2').execute

    expect(result.to_a).to match_array([])
  end
end
