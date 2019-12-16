# frozen_string_literal: true

require 'spec_helper'

describe LabelsHelper do
  describe '#show_label_issuables_link?' do
    shared_examples 'a valid response to show_label_issuables_link?' do |issuables_type, when_enabled = true, when_disabled = false|
      context "when asking for a #{issuables_type} link" do
        subject { show_label_issuables_link?(label.present(issuable_subject: nil), issuables_type) }

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
        it_behaves_like 'a valid response to show_label_issuables_link?', :issues, true, true
      end

      context 'when asking for a merge requests link' do
        it_behaves_like 'a valid response to show_label_issuables_link?', :merge_requests, true, true
      end
    end
  end

  describe 'link_to_label' do
    let(:project) { create(:project) }
    let(:label) { create(:label, project: project) }
    let(:subject) { nil }
    let(:label_presenter) { label.present(issuable_subject: subject) }

    context 'without subject' do
      it "uses the label's project" do
        expect(link_to_label(label_presenter)).to match %r{<a href="/#{label.project.full_path}/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a project as subject' do
      let(:namespace) { build(:namespace, name: 'foo3') }
      let(:subject) { build(:project, namespace: namespace, name: 'bar3') }

      it 'links to project issues page' do
        expect(link_to_label(label_presenter)).to match %r{<a href="/foo3/bar3/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a group as subject' do
      let(:subject) { build(:group, name: 'bar') }

      it 'links to group issues page' do
        expect(link_to_label(label_presenter)).to match %r{<a href="/groups/bar/-/issues\?label_name%5B%5D=#{label.name}">.*</a>}
      end
    end

    context 'with a type argument' do
      ['issue', :issue].each do |type|
        context "set to #{type}" do
          it 'links to correct page' do
            expect(link_to_label(label_presenter, type: type)).to match %r{<a href="/#{label.project.full_path}/#{type.to_s.pluralize}\?label_name%5B%5D=#{label.name}">.*</a>}
          end
        end
      end

      ['merge_request', :merge_request].each do |type|
        context "set to #{type}" do
          it 'links to correct page' do
            expect(link_to_label(label_presenter, type: type)).to match %r{<a href="/#{label.project.full_path}/-/#{type.to_s.pluralize}\?label_name%5B%5D=#{label.name}">.*</a>}
          end
        end
      end
    end

    context 'with a tooltip argument' do
      context 'set to false' do
        it 'does not include the has-tooltip class' do
          expect(link_to_label(label_presenter, tooltip: false)).not_to match /has-tooltip/
        end
      end
    end

    context 'with block' do
      it 'passes the block to link_to' do
        link = link_to_label(label_presenter) { 'Foo' }
        expect(link).to match('Foo')
      end
    end

    context 'without block' do
      it 'uses render_colored_label as the link content' do
        expect(self).to receive(:render_colored_label)
          .with(label_presenter, tooltip: true).and_return('Foo')
        expect(link_to_label(label_presenter)).to match('Foo')
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
        expect(create_label_title(group)).to eq _('Create group label')
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "Create project label"' do
        expect(create_label_title(project)).to eq _('Create project label')
      end
    end

    context 'with no subject' do
      it 'returns "Create new label"' do
        expect(create_label_title(nil)).to eq _('Create new label')
      end
    end
  end

  describe 'manage_labels_title' do
    set(:group) { create(:group) }

    context 'with a group as subject' do
      it 'returns "Manage group labels"' do
        expect(manage_labels_title(group)).to eq _('Manage group labels')
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "Manage project labels"' do
        expect(manage_labels_title(project)).to eq _('Manage project labels')
      end
    end

    context 'with no subject' do
      it 'returns "Manage labels"' do
        expect(manage_labels_title(nil)).to eq _('Manage labels')
      end
    end
  end

  describe 'view_labels_title' do
    set(:group) { create(:group) }

    context 'with a group as subject' do
      it 'returns "View group labels"' do
        expect(view_labels_title(group)).to eq _('View group labels')
      end
    end

    context 'with a project as subject' do
      set(:project) { create(:project, namespace: group) }

      it 'returns "View project labels"' do
        expect(view_labels_title(project)).to eq _('View project labels')
      end
    end

    context 'with no subject' do
      it 'returns "View labels"' do
        expect(view_labels_title(nil)).to eq _('View labels')
      end
    end
  end

  describe 'labels_filter_path' do
    let(:group) { create(:group) }
    let(:project) { create(:project) }

    it 'links to the dashboard labels page' do
      expect(labels_filter_path).to eq(dashboard_labels_path)
    end

    it 'links to the group labels page' do
      assign(:group, group)

      expect(helper.labels_filter_path).to eq(group_labels_path(group))
    end

    it 'links to the project labels page' do
      assign(:project, project)

      expect(helper.labels_filter_path).to eq(project_labels_path(project))
    end

    it 'supports json format' do
      expect(labels_filter_path(format: :json)).to eq(dashboard_labels_path(format: :json))
    end
  end

  describe 'presented_labels_sorted_by_title' do
    let(:labels) do
      [build(:label, title: 'a'),
       build(:label, title: 'B'),
       build(:label, title: 'c'),
       build(:label, title: 'D')]
    end

    it 'sorts labels alphabetically' do
      sorted_ids = presented_labels_sorted_by_title(labels, nil).map(&:id)

      expect(sorted_ids)
        .to match_array([labels[1].id, labels[3].id, labels[0].id, labels[2].id])
    end

    it 'returns an array of label presenters' do
      expect(presented_labels_sorted_by_title(labels, nil))
        .to all(be_a(LabelPresenter))
    end
  end

  describe 'label_from_hash' do
    it 'builds a group label with whitelisted attributes' do
      label = label_from_hash({ title: 'foo', color: 'bar', id: 1, group_id: 1 })

      expect(label).to be_a(GroupLabel)
      expect(label.id).to be_nil
      expect(label.title).to eq('foo')
      expect(label.color).to eq('bar')
    end

    it 'builds a project label with whitelisted attributes' do
      label = label_from_hash({ title: 'foo', color: 'bar', id: 1, project_id: 1 })

      expect(label).to be_a(ProjectLabel)
      expect(label.id).to be_nil
      expect(label.title).to eq('foo')
      expect(label.color).to eq('bar')
    end
  end

  describe '#label_status_tooltip' do
    let(:status) { 'unsubscribed'.inquiry }
    subject { label_status_tooltip(label.present(issuable_subject: nil), status) }

    context 'with a project label' do
      let(:label) { create(:label, title: 'bug') }

      it { is_expected.to eq('Subscribe at project level') }
    end

    context 'with a group label' do
      let(:label) { create(:group_label, title: 'bug') }

      it { is_expected.to eq('Subscribe at group level') }
    end
  end

  describe '#label_tooltip_title' do
    let(:html) { '<img src="example.png">This is an image</img>' }
    let(:label_with_html_content) { create(:label, title: 'test', description: html) }

    it 'removes HTML' do
      tooltip = label_tooltip_title(label_with_html_content)
      expect(tooltip).to eq('This is an image')
    end
  end
end
