require 'spec_helper'

describe SearchContext do
  let(:found_namespace) { create(:namespace, name: 'searchable namespace', path:'another_thing') }
  let(:user) { create(:user, namespace: found_namespace) }
  let!(:found_project) { create(:project, name: 'searchable_project', creator_id: user.id, namespace: found_namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

  let(:unfound_namespace) { create(:namespace, name: 'unfound namespace', path: 'yet_something_else') }
  let!(:unfound_project) { create(:project, name: 'unfound_project', creator_id: user.id, namespace: unfound_namespace, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
  
  let(:internal_namespace) { create(:namespace, path: 'something_internal',name: 'searchable internal namespace') }
  let(:internal_user) { create(:user, namespace: internal_namespace) }
  let!(:internal_project) { create(:project, name: 'searchable_internal_project', creator_id: internal_user.id, namespace: internal_namespace, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
  
  let(:public_namespace) { create(:namespace, path: 'something_public',name: 'searchable public namespace') }
  let(:public_user) { create(:user, namespace: public_namespace) }
  let!(:public_project) { create(:project, name: 'searchable_public_project', creator_id: public_user.id, namespace: public_namespace, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  describe '#execute' do
    it 'public projects should be searchable' do
      context = SearchContext.new([found_project.id], nil, {search_code:  false, search: "searchable"})
      results = context.execute
      results[:projects].should == [found_project, public_project]
    end

    it 'internal projects should be searchable' do
      context = SearchContext.new([found_project.id], user, {search_code:  false, search: "searchable"})
      results = context.execute
      # can't seem to rely on the return order, so check this way
      #subject { results[:projects] }
      results[:projects].should have(3).items
      results[:projects].should include(found_project)
      results[:projects].should include(internal_project)
      results[:projects].should include(public_project)
    end

    it 'namespace name should be searchable' do
      context = SearchContext.new([found_project.id], user, {search_code:  false, search: "searchable namespace"})
      results = context.execute
      results[:projects].should == [found_project]
    end
  end
end
