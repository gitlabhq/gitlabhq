require 'spec_helper'

describe SearchHelper do
  describe '#parse_search_result_from_elastic' do
    let(:user) { create(:user) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      Gitlab::Elastic::Helper.create_empty_index
    end

    after do
      Gitlab::Elastic::Helper.delete_index
      stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
    end

    it "returns parsed result" do
      project = create :project, :repository

      project.repository.index_blobs

      Gitlab::Elastic::Helper.refresh_index

      result = project.repository.search(
        'def popen',
        type: :blob,
        options: { highlight: true }
      )[:blobs][:results][0]

      _, parsed_result = helper.parse_search_result(result)

      expect(parsed_result.ref). to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      expect(parsed_result.filename).to eq('files/ruby/popen.rb')
      expect(parsed_result.startline).to eq(2)
      expect(parsed_result.data).to include("Popen")
    end

    it 'does not return project that does not exist' do
      Gitlab::Elastic::Helper.create_empty_index

      @project_2 = create :project, :repository

      @project_2.repository.create_file(
        user,
        'thing.txt',
        ' function application.js ',
        message: 'Find me',
        branch_name: 'master')

      @project_2.repository.index_blobs
      Gitlab::Elastic::Helper.refresh_index
      @project_2.destroy

      blob = { _parent: @project_2.id }

      result = find_project_for_result_blob(blob)

      expect(result).to be(nil)
    end
  end
end
