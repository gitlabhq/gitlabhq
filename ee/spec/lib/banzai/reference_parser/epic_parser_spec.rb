require 'spec_helper'

describe Banzai::ReferenceParser::EpicParser do
  include ReferenceParserHelpers

  def link(epic_id)
    link = empty_html_link
    link['data-epic'] = epic_id.to_s
    link
  end

  let(:user)           { create(:user) }
  let(:public_group)   { create(:group, :public) }
  let(:private_group1) { create(:group, :private) }
  let(:private_group2) { create(:group, :private) }
  let(:public_epic)    { create(:epic, group: public_group) }
  let(:private_epic1)  { create(:epic, group: private_group1) }
  let(:private_epic2)  { create(:epic, group: private_group2) }
  let(:nodes) do
    [link(public_epic.id), link(private_epic1.id), link(private_epic2.id)]
  end

  subject { described_class.new(Banzai::RenderContext.new(nil, user)) }

  describe '#nodes_visible_to_user' do
    before do
      private_group1.add_developer(user)
    end

    context 'when the epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'returns the nodes the user can read for valid epic nodes' do
        expected_result = [nodes[0], nodes[1]]

        expect(subject.nodes_visible_to_user(user, nodes)).to match_array(expected_result)
      end

      it 'returns an empty array for nodes without required data-attributes' do
        expect(subject.nodes_visible_to_user(user, [empty_html_link])).to be_empty
      end
    end

    context 'when the epics feature is disabled' do
      it 'returns an empty array' do
        expect(subject.nodes_visible_to_user(user, nodes)).to be_empty
      end
    end
  end

  describe '#referenced_by' do
    context 'when using an existing epics IDs' do
      it 'returns an Array of epics' do
        expected_result = [public_epic, private_epic1, private_epic2]

        expect(subject.referenced_by(nodes)).to match_array(expected_result)
      end

      it 'returns an empty Array for empty list of nodes' do
        expect(subject.referenced_by([])).to be_empty
      end
    end

    context 'when epic with given ID does not exist' do
      it 'returns an empty Array' do
        expect(subject.referenced_by([link(9999)])).to be_empty
      end
    end
  end

  describe '#records_for_nodes' do
    it 'returns a Hash containing the epics for a list of nodes' do
      expected_hash = {
        nodes[0] => public_epic,
        nodes[1] => private_epic1,
        nodes[2] => private_epic2
      }
      expect(subject.records_for_nodes(nodes)).to eq(expected_hash)
    end
  end
end
