require('spec_helper')

describe ProjectsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:png)     { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png') }
  let(:jpg)     { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:gif)     { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }
  let(:txt)     { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  describe "POST #upload_image" do
    before do
      sign_in(user)
    end

    context "without params['markdown_img']" do
      it "returns an error" do
        post :upload_image, id: project.to_param
        expect(response.status).to eq(404)
      end
    end

    context "with invalid file" do
      before do
        post :upload_image, id: project.to_param, markdown_img: @img
      end

      it "returns an error" do
        expect(response.status).to eq(404)
      end
    end

    context "with valid file" do
      before do
        post :upload_image, id: project.to_param, markdown_img: @img
      end

      it "returns a content with original filename and new link." do
        link = { alt: 'rails_sample', link: '' }.to_json
        expect(response.body).to have_content link
      end
    end
  end
end