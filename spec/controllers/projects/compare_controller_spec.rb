require 'spec_helper'

describe Projects::CompareController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:ref_from) { "improve%2Fawesome" }
  let(:ref_to) { "feature" }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  it 'compare should show some diffs' do
    get(:show,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        from: ref_from,
        to: ref_to)

    expect(response).to be_success
    expect(assigns(:diffs).first).to_not be_nil
    expect(assigns(:commits).length).to be >= 1
  end

  it 'compare should show some diffs with ignore whitespace change option' do
    get(:show,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        from: '08f22f25',
        to: '66eceea0',
        w: 1)

    expect(response).to be_success
    expect(assigns(:diffs).first).to_not be_nil
    expect(assigns(:commits).length).to be >= 1
    # without whitespace option, there are more than 2 diff_splits
    diff_splits = assigns(:diffs).first.diff.split("\n")
    expect(diff_splits.length).to be <= 2
  end

  describe 'non-existent refs' do
    it 'invalid source ref' do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          from: 'non-existent',
          to: ref_to)

      expect(response).to be_success
      expect(assigns(:diffs).to_a).to eq([])
      expect(assigns(:commits)).to eq([])
    end

    it 'invalid target ref' do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          from: ref_from,
          to: 'non-existent')

      expect(response).to be_success
      expect(assigns(:diffs)).to eq(nil)
      expect(assigns(:commits)).to eq(nil)
    end
  end
end
