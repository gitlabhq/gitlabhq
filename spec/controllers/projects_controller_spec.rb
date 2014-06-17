require('spec_helper')

describe ProjectsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:jpg)     { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt)     { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  describe "POST #upload_image" do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context "without params['markdown_img']" do
      it "returns an error" do
        post :upload_image, id: project.to_param, format: :json
        expect(response.status).to eq(422)
      end
    end

    context "with invalid file" do
      before do
        post :upload_image, id: project.to_param, markdown_img: txt, format: :json
      end

      it "returns an error" do
        expect(response.status).to eq(422)
      end
    end

    context "with valid file" do
      before do
        post :upload_image, id: project.to_param, markdown_img: jpg, format: :json
      end

      it "returns a content with original filename and new link." do
        expect(response.body).to match "\"alt\":\"rails_sample\""
        expect(response.body).to match "\"url\":\"http://test.host/uploads/#{project.path_with_namespace}"
      end
    end
  end
end
