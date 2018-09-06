require 'spec_helper'

describe BlobHelper do
  include TreeHelper

  describe '#licenses_for_select' do
    subject(:result) { helper.licenses_for_select }

    let(:categories) { result.keys }
    let(:custom) { result[:Custom] }
    let(:popular) { result[:Popular] }
    let(:other) { result[:Other] }

    let(:project) { create(:project) }

    it 'returns Custom licenses when enabled' do
      stub_licensed_features(custom_file_templates: true)
      stub_ee_application_setting(file_template_project: project)

      expect(Gitlab::Template::CustomLicenseTemplate)
        .to receive(:all)
        .with(project)
        .and_return([OpenStruct.new(name: "name")])

      expect(categories).to contain_exactly(:Popular, :Other, :Custom)
      expect(custom).to contain_exactly({ name: "name", id: "name" })
      expect(popular).to be_present
      expect(other).to be_present
    end

    it 'returns no Custom licenses when disabled' do
      stub_licensed_features(custom_file_templates: false)

      expect(categories).to contain_exactly(:Popular, :Other)
      expect(custom).to be_nil
      expect(popular).to be_present
      expect(other).to be_present
    end
  end
end
