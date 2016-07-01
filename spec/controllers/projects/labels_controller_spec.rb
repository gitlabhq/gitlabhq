require 'spec_helper'

describe Projects::LabelsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #index' do
    def create_label(attributes)
      create(:label, attributes.merge(project: project))
    end

    before do
      15.times { |i| create_label(priority: (i % 3) + 1, title: "label #{15 - i}") }
      5.times { |i| create_label(title: "label #{100 - i}") }

      get :index, namespace_id: project.namespace.to_param, project_id: project.to_param
    end

    context '@prioritized_labels' do
      let(:prioritized_labels) { assigns(:prioritized_labels) }

      it 'contains only prioritized labels' do
        expect(prioritized_labels).to all(have_attributes(priority: a_value > 0))
      end

      it 'is sorted by priority, then label title' do
        priorities_and_titles = prioritized_labels.pluck(:priority, :title)

        expect(priorities_and_titles.sort).to eq(priorities_and_titles)
      end
    end

    context '@labels' do
      let(:labels) { assigns(:labels) }

      it 'contains only unprioritized labels' do
        expect(labels).to all(have_attributes(priority: nil))
      end

      it 'is sorted by label title' do
        titles = labels.pluck(:title)

        expect(titles.sort).to eq(titles)
      end
    end
  end
end
