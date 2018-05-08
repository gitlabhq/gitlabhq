require 'spec_helper'

describe 'GlobalSearch' do
  let(:features) { %i(issues merge_requests repository builds wiki snippets) }
  let(:admin) { create :user, admin: true }
  let(:auditor) {create :user, auditor: true }
  let(:non_member) { create :user }
  let(:external_non_member) { create :user, external: true }
  let(:member) { create :user }
  let(:external_member) { create :user, external: true }
  let(:guest) { create :user }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index

    project.add_developer(member)
    project.add_developer(external_member)
    project.add_guest(guest)
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  context "Respect feature visibility levels" do
    context "Private projects" do
      let(:project) { create(:project, :private, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Internal projects" do
      let(:project) { create(:project, :internal, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are private" do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Public projects" do
      let(:project) { create(:project, :public, :repository, :wiki_repo) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(external_member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end

      it "finds items if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_items_to_be_found(external_non_member)
        expect_items_to_be_found(nil)
      end

      it "shows items to member only if features are private" do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(external_member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(external_non_member)
        expect_no_items_to_be_found(nil)
      end
    end
  end

  def create_items(project, feature_settings = nil)
    Sidekiq::Testing.inline! do
      create :issue, title: 'term', project: project
      create :merge_request, title: 'term', target_project: project, source_project: project
      project.wiki.create_page('index_page', 'term')

      # Going through the project ensures its elasticsearch document is updated
      project.update!(project_feature_attributes: feature_settings) if feature_settings

      project.repository.index_blobs
      project.repository.index_commits
      project.wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end
  end

  # access_level can be :disabled, :enabled or :private
  def feature_settings(access_level)
    Hash[features.collect { |k| ["#{k}_access_level", ProjectFeature.const_get(access_level.to_s.upcase)] }]
  end

  def expect_no_items_to_be_found(user)
    results = search(user, 'term')
    expect(results.issues_count).to eq(0)
    expect(results.merge_requests_count).to eq(0)
    expect(results.wiki_blobs_count).to eq(0)
    expect(search(user, 'def').blobs_count).to eq(0)
    expect(search(user, 'add').commits_count).to eq(0)
  end

  def expect_items_to_be_found(user)
    results = search(user, 'term')
    expect(results.issues_count).not_to eq(0)
    expect(results.merge_requests_count).not_to eq(0)
    expect(results.wiki_blobs_count).not_to eq(0)
    expect(search(user, 'def').blobs_count).not_to eq(0)
    expect(search(user, 'add').commits_count).not_to eq(0)
  end

  def expect_non_code_items_to_be_found(user)
    results = search(user, 'term')
    expect(results.issues_count).not_to eq(0)
    expect(results.wiki_blobs_count).not_to eq(0)
    expect(results.merge_requests_count).to eq(0)
    expect(search(user, 'def').blobs_count).to eq(0)
    expect(search(user, 'add').commits_count).to eq(0)
  end

  def search(user, search, snippets: false)
    SearchService.new(user, search: search, snippets: snippets ? 'true' : 'false').search_results
  end
end
