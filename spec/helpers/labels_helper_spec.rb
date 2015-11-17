require 'spec_helper'

describe LabelsHelper do
  describe 'link_to_label' do
    let(:project) { create(:empty_project) }
    let(:label)   { create(:label, project: project) }

    context 'with @project set' do
      before do
        @project = project
      end

      it 'uses the instance variable' do
        expect(label).not_to receive(:project)
        link_to_label(label)
      end
    end

    context 'without @project set' do
      it "uses the label's project" do
        expect(label).to receive(:project).and_return(project)
        link_to_label(label)
      end
    end

    context 'with a named project argument' do
      it 'uses the provided project' do
        arg = double('project')
        expect(arg).to receive(:namespace).and_return('foo')
        expect(arg).to receive(:to_param).and_return('foo')

        link_to_label(label, project: arg)
      end

      it 'takes precedence over other types' do
        @project = project
        expect(@project).not_to receive(:namespace)
        expect(label).not_to receive(:project)

        arg = double('project', namespace: 'foo', to_param: 'foo')
        link_to_label(label, project: arg)
      end
    end

    context 'with block' do
      it 'passes the block to link_to' do
        link = link_to_label(label) { 'Foo' }
        expect(link).to match('Foo')
      end
    end

    context 'without block' do
      it 'uses render_colored_label as the link content' do
        expect(self).to receive(:render_colored_label).
          with(label).and_return('Foo')
        expect(link_to_label(label)).to match('Foo')
      end
    end
  end

  describe 'text_color_for_bg' do
    it 'uses light text on dark backgrounds' do
      expect(text_color_for_bg('#222E2E')).to eq('#FFFFFF')
    end

    it 'uses dark text on light backgrounds' do
      expect(text_color_for_bg('#EEEEEE')).to eq('#333333')
    end
  end
end
