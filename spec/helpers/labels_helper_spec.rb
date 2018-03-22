require 'spec_helper'

describe LabelsHelper do
  describe '#show_label_issuables_link?' do
    shared_examples 'a valid response to show_label_issuables_link?' do |issuables_type, when_enabled = true, when_disabled = false|
      let(:context_project) { project }

      context "when asking for a #{issuables_type} link" do
        subject { show_label_issuables_link?(label, issuables_type, project: context_project) }

        context "when #{issuables_type} are enabled for the project" do
          let(:project) { create(:project, "#{issuables_type}_access_level": ProjectFeature::ENABLED) }

          it { is_expected.to be(when_enabled) }
        end

        context "when #{issuables_type} are disabled for the project" do
          let(:project) { create(:project, :public, "#{issuables_type}_access_level": ProjectFeature::DISABLED) }

          it { is_expected.to be(when_disabled) }
        end
      end
    end

    context 'with a project label' do
      let(:label) { create(:label, project: project, title: 'bug') }

      context 'when asking for an issue link' do
        it_behaves_like 'a valid response to show_label_issuables_link?', :issues
      end

      context 'when asking for a merge requests link' do
        it_behaves_like 'a valid response to show_label_issuables_link?', :merge_requests
      end
    end

    context 'with a group label' do
      set(:group) { create(:group) }
      let(:label) { create(:group_label, group: group, title: 'bug') }

      context 'when asking for an issue link' do
        context 'in the context of a project' do
          it_behaves_like 'a valid response to show_label_issuables_link?', :issues, true, true
        end

        context 'in the context of a group' do
          let(:context_project) { nil }

          it_behaves_like 'a valid response to show_label_issuables_link?', :issues, true, true
        end
      end

      context 'when asking for a merge requests link' do
        context 'in the context of a project' do
          it_behaves_like 'a valid response to show_label_issuables_link?', :merge_requests, true, true
        end

        context 'in the context of a group' do
          let(:context_project) { nil }

          it_behaves_like 'a valid response to show_label_issuables_link?', :merge_requests, true, true
        end
      end
    end
  end

  describe 'link_to_label' do
    let(:project) { create(:project) }
    let(:label) { create(:label, project: project) }

    context 'without subject' do
      it "uses the label's project" do
        expect(link_to_label(label)).to match %r{<a href="/#{label.project.full_path}/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a project as subject' do
      let(:namespace) { build(:namespace, name: 'foo3') }
      let(:another_project) { build(:project, namespace: namespace, name: 'bar3') }

      it 'links to project issues page' do
        expect(link_to_label(label, subject: another_project)).to match %r{<a href="/foo3/bar3/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a group as subject' do
      let(:group) { build(:group, name: 'bar') }

      it 'links to group issues page' do
        expect(link_to_label(label, subject: group)).to match %r{<a href="/groups/bar/-/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a type argument' do
      ['issue', :issue, 'merge_request', :merge_request].each do |type|
        context "set to #{type}" do
          it 'links to correct page' do
            expect(link_to_label(label, type: type)).to match %r{<a href="/#{label.project.full_path}/#{type.to_s.pluralize}\?label_name%5B%5D=#{label.name}">.*</a>}
          end
        end
      end
    end

    context 'with a tooltip argument' do
      context 'set to false' do
        it 'does not include the has-tooltip class' do
          expect(link_to_label(label, tooltip: false)).not_to match /has-tooltip/
        end
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
        expect(self).to receive(:render_colored_label)
          .with(label, tooltip: true).and_return('Foo')
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

    it 'supports RGB triplets' do
      expect(text_color_for_bg('#FFF')).to eq '#333333'
      expect(text_color_for_bg('#000')).to eq '#FFFFFF'
    end
  end

  describe 'create_label_title' do
    set(:group) { create(:group) }

    context 'with a group as subject' do
      it 'returns "Create group label"' do
        expect(create_label_title(group)).to eq 'Create group label'
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "Create project label"' do
        expect(create_label_title(project)).to eq 'Create project label'
      end
    end

    context 'with no subject' do
      it 'returns "Create new label"' do
        expect(create_label_title(nil)).to eq 'Create new label'
      end
    end
  end

  describe 'manage_labels_title' do
    set(:group) { create(:group) }

    context 'with a group as subject' do
      it 'returns "Manage group labels"' do
        expect(manage_labels_title(group)).to eq 'Manage group labels'
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "Manage project labels"' do
        expect(manage_labels_title(project)).to eq 'Manage project labels'
      end
    end

    context 'with no subject' do
      it 'returns "Manage labels"' do
        expect(manage_labels_title(nil)).to eq 'Manage labels'
      end
    end
  end

  describe 'view_labels_title' do
    set(:group) { create(:group) }

    context 'with a group as subject' do
      it 'returns "View group labels"' do
        expect(view_labels_title(group)).to eq 'View group labels'
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "View project labels"' do
        expect(view_labels_title(project)).to eq 'View project labels'
      end
    end

    context 'with no subject' do
      it 'returns "View labels"' do
        expect(view_labels_title(nil)).to eq 'View labels'
      end
    end
  end
end
