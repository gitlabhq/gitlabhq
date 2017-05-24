require 'spec_helper'

describe 'GlobalSearch' do
  let(:features) { %i(issues merge_requests repository builds) }
  let(:admin) { create :user, admin: true }
  let(:auditor) {create :user, auditor: true }
  let(:non_member) { create :user }
  let(:member) { create :user }
  let(:guest) { create :user }

  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index

    project.team << [member, :developer]
    project.team << [guest, :guest]
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  context "Respect feature visibility levels" do
    context "Private projects" do
      let(:project) { create(:project, :private) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Internal projects" do
      let(:project) { create(:project, :internal) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end

      it "shows items to member only if features are private" do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end
    end

    context "Public projects" do
      let(:project) { create(:project, :public) }

      # The feature can be disabled but the data may actually exist
      it "does not find items if features are disabled" do
        create_items(project, feature_settings(:disabled))

        expect_no_items_to_be_found(admin)
        expect_no_items_to_be_found(auditor)
        expect_no_items_to_be_found(member)
        expect_no_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end

      it "finds items if features are enabled" do
        create_items(project, feature_settings(:enabled))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_items_to_be_found(guest)
        expect_items_to_be_found(non_member)
        expect_items_to_be_found(nil)
      end

      it "shows items to member only if features are private" do
        create_items(project, feature_settings(:private))

        expect_items_to_be_found(admin)
        expect_items_to_be_found(auditor)
        expect_items_to_be_found(member)
        expect_non_code_items_to_be_found(guest)
        expect_no_items_to_be_found(non_member)
        expect_no_items_to_be_found(nil)
      end
    end
  end

  def create_items(project, feature_settings = nil)
    Sidekiq::Testing.inline! do
      create :issue, title: 'term', project: project
      create :merge_request, title: 'term', target_project: project, source_project: project

      project.project_feature.update!(feature_settings) if feature_settings

      project.repository.index_blobs
      project.repository.index_commits

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
    expect(search(user, 'def').blobs_count).to eq(0)
    expect(search(user, 'add').commits_count).to eq(0)
  end

  def expect_items_to_be_found(user)
    results = search(user, 'term')
    expect(results.issues_count).not_to eq(0)
    expect(results.merge_requests_count).not_to eq(0)
    expect(search(user, 'def').blobs_count).not_to eq(0)
    expect(search(user, 'add').commits_count).not_to eq(0)
  end

  def expect_non_code_items_to_be_found(user)
    results = search(guest, 'term')
    expect(results.issues_count).not_to eq(0)
    expect(results.merge_requests_count).to eq(0)
    expect(search(guest, 'def').blobs_count).to eq(0)
    expect(search(guest, 'add').commits_count).to eq(0)
  end

  def search(user, search)
    Search::GlobalService.new(user, search: search).execute
  end
end
