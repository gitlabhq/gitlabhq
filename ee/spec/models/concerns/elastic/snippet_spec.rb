require 'spec_helper'

describe Snippet, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'searching snippets by code' do
    let!(:author) { create(:user) }
    let!(:project) { create(:project) }

    let!(:public_snippet)   { create(:snippet, :public, content: 'password: XXX') }
    let!(:internal_snippet) { create(:snippet, :internal, content: 'password: XXX') }
    let!(:private_snippet)  { create(:snippet, :private, content: 'password: XXX', author: author) }

    let!(:project_public_snippet)   { create(:snippet, :public, project: project, content: 'password: 123') }
    let!(:project_internal_snippet) { create(:snippet, :internal, project: project, content: 'password: 456') }
    let!(:project_private_snippet)  { create(:snippet, :private, project: project, content: 'password: 789') }

    before do
      Gitlab::Elastic::Helper.refresh_index
    end

    it 'returns only public snippets when user is blank' do
      result = described_class.elastic_search_code('password', options: { user: nil })

      expect(result.total_count).to eq(1)
      expect(result.records).to match_array [public_snippet]
    end

    it 'returns only public and internal personal snippets for non-members' do
      non_member = create(:user)

      result = described_class.elastic_search_code('password', options: { user: non_member })

      expect(result.total_count).to eq(2)
      expect(result.records).to match_array [public_snippet, internal_snippet]
    end

    it 'returns public, internal snippets, and project private snippets for project members' do
      member = create(:user)
      project.add_developer(member)

      result = described_class.elastic_search_code('password', options: { user: member })

      expect(result.total_count).to eq(5)
      expect(result.records).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
    end

    it 'returns private snippets where the user is the author' do
      result = described_class.elastic_search_code('password', options: { user: author })

      expect(result.total_count).to eq(3)
      expect(result.records).to match_array [public_snippet, internal_snippet, private_snippet]
    end

    it 'supports advanced search syntax' do
      member = create(:user)
      project.add_reporter(member)

      result = described_class.elastic_search_code('password +(123 | 789)', options: { user: member })

      expect(result.total_count).to eq(2)
      expect(result.records).to match_array [project_public_snippet, project_private_snippet]
    end

    [:admin, :auditor].each do |user_type|
      it "returns all snippets for #{user_type}" do
        superuser = create(user_type)

        result = described_class.elastic_search_code('password', options: { user: superuser })

        expect(result.total_count).to eq(6)
        expect(result.records).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
      end
    end

    describe 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
      end

      it 'returns public, internal snippets, but not project snippets' do
        member = create(:user)
        project.add_developer(member)
        expect(Ability).to receive(:allowed?).with(member, :read_cross_project) { false }

        result = described_class.elastic_search_code('password', options: { user: member })

        expect(result.records).to match_array [public_snippet, internal_snippet]
      end
    end
  end

  it 'searches snippets by title and file_name' do
    user = create(:user)

    Sidekiq::Testing.inline! do
      create(:snippet, :public, title: 'home')
      create(:snippet, :private, title: 'home 1')
      create(:snippet, :public, file_name: 'index.php')
      create(:snippet)

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { user: user }

    expect(described_class.elastic_search('home', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('index.php', options: options).total_count).to eq(1)
  end

  it 'returns json with all needed elements' do
    snippet = create(:project_snippet)

    expected_hash = snippet.attributes.extract!(
      'id',
      'title',
      'file_name',
      'content',
      'created_at',
      'updated_at',
      'state',
      'project_id',
      'author_id',
      'visibility_level'
    )

    expect(snippet.as_indexed_json).to eq(expected_hash)
  end
end
