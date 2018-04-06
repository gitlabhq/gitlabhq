require 'spec_helper'

describe ProjectWiki, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it "searches wiki page" do
    project = create :project

    Sidekiq::Testing.inline! do
      project.wiki.create_page("index_page", "Bla bla term1")
      project.wiki.create_page("omega_page", "Bla bla term2")
      project.wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(project.wiki.search('term1', type: :blob)[:blobs][:total_count]).to eq(1)
    expect(project.wiki.search('term1 | term2', type: :blob)[:blobs][:total_count]).to eq(2)
  end
end
