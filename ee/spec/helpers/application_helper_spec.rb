require 'spec_helper'

describe ApplicationHelper do
  describe '#autocomplete_data_sources' do
    let(:object) { create(:group) }
    let(:noteable_type) { Epic }
    it 'returns paths for autocomplete_sources_controller' do
      sources = helper.autocomplete_data_sources(object, noteable_type)
      expect(sources.keys).to match_array([:members])
      sources.keys.each do |key|
        expect(sources[key]).not_to be_nil
      end
    end
  end

  context 'when both CE and EE has partials with the same name' do
    let(:partial) { 'shared/issuable/form/default_templates' }
    let(:view) { 'projects/merge_requests/show' }
    let(:project) { build_stubbed(:project) }

    describe '#render_ce' do
      before do
        helper.instance_variable_set(:@project, project)

        allow(project).to receive(:feature_available?)
      end

      it 'renders the CE partial' do
        helper.render_ce(partial)

        expect(project).not_to receive(:feature_available?)
      end
    end

    describe '#find_ce_template' do
      let(:expected_partial_path) do
        "app/views/#{File.dirname(partial)}/_#{File.basename(partial)}.html.haml"
      end
      let(:expected_view_path) do
        "app/views/#{File.dirname(view)}/#{File.basename(view)}.html.haml"
      end

      it 'finds the CE partial' do
        ce_partial = helper.find_ce_template(partial)

        expect(ce_partial.inspect).to eq(expected_partial_path)

        # And it could still find the EE partial
        ee_partial = helper.lookup_context.find(partial, [], true)
        expect(ee_partial.inspect).to eq("ee/#{expected_partial_path}")
      end

      it 'finds the CE view' do
        ce_view = helper.find_ce_template(view)

        expect(ce_view.inspect).to eq(expected_view_path)

        # And it could still find the EE view
        ee_view = helper.lookup_context.find(view, [], false)
        expect(ee_view.inspect).to eq("ee/#{expected_view_path}")
      end
    end
  end
end
