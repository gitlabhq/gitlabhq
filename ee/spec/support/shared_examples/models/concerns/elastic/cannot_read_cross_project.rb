shared_examples 'no results when the user cannot read cross project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:project2) { create(:project, :public) }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
    record1
    record2
    Gitlab::Elastic::Helper.refresh_index
  end

  it 'returns the record if a single project was passed' do
    result = described_class.elastic_search(
      'test',
      options: {
        current_user: user,
        project_ids: [project.id]
      }
    )

    expect(result.records).to match_array [record1]
  end

  it 'does not return anything when trying to search cross project' do
    result = described_class.elastic_search(
      'test',
      options: {
        current_user: user,
        project_ids: [project.id, project2.id]
      }
    )

    expect(result.records).to be_empty
  end
end
