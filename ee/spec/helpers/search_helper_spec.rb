require 'spec_helper'

describe SearchHelper do
  describe '#parse_search_result_from_elastic' do
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

      parsed_result = helper.parse_search_result(result)

      expect(parsed_result.ref). to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      expect(parsed_result.filename).to eq('files/ruby/popen.rb')
      expect(parsed_result.startline).to eq(2)
      expect(parsed_result.data).to include("Popen")
    end
  end
end
