require('spec_helper')

describe ProjectsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:jpg)     { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt)     { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  describe "POST #upload_file" do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context "without params['markdown_file']" do
      it "returns an error" do
        post :upload_file, id: project.to_param, format: :json
        expect(response.status).to eq(422)
      end
    end

    context "with valid image" do
      before do
        post :upload_file, id: project.to_param, markdown_file: jpg, format: :json
      end

      it "returns a content with original filename, new link, and correct type." do
        expect(response.body).to match "\"alt\":\"rails_sample\""
        expect(response.body).to match "\"url\":\"http://test.host/uploads/#{project.path_with_namespace}"
        expect(response.body).to match "\"is_image\": true
      end
    end

    context "with valid non-image file" do
      before do
        post :upload_file, id: project.to_param, markdown_file: txt, format: :json
      end

      it "returns a content with original filename, new link, and correct type." do
        expect(response.body).to match "\"alt\":\"doc_sample\""
        expect(response.body).to match "\"url\":\"http://test.host/uploads/#{project.path_with_namespace}"
        expect(response.body).to match "\"is_image\": false
      end
    end
  end
end
