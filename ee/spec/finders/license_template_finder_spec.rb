require 'spec_helper'

describe LicenseTemplateFinder do
  describe '#execute' do
    subject(:result) { described_class.new(params).execute }

    let(:params) { {} }

    let(:project) { create(:project) }
    let(:custom) { result.select { |template| template.category == :Custom } }

    before do
      stub_ee_application_setting(file_template_project: project)
      allow(Gitlab::Template::LicenseTemplate)
        .to receive(:all)
        .with(project)
        .and_return([OpenStruct.new(name: "custom template")])
    end

    context 'custom file templates feature enabled' do
      before do
        stub_licensed_features(custom_file_templates: true)
      end

      it 'includes custom file templates' do
        expect(custom.map(&:name)).to contain_exactly("custom template")
      end

      it 'skips custom file templates when only "popular" templates are requested' do
        params[:popular] = true

        expect(custom).to be_empty
      end
    end

    context 'custom file templates feature disabled' do
      it 'does not include custom file templates' do
        stub_licensed_features(custom_file_templates: false)

        expect(custom).to be_empty
      end
    end
  end
end
