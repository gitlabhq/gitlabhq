require('spec_helper')

describe Projects::UploadsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:jpg)     { fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt)     { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }

  describe "POST #create" do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context "without params['file']" do
      it "returns an error" do
        post :create, 
          namespace_id: project.namespace.to_param,
          project_id: project.to_param, 
          format: :json
        expect(response.status).to eq(422)
      end
    end

    context 'with valid image' do
      before do
        post :create,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          file: jpg,
          format: :json
      end

      it 'returns a content with original filename, new link, and correct type.' do
        expect(response.body).to match '\"alt\":\"rails_sample\"'
        expect(response.body).to match "\"url\":\"/uploads"
        expect(response.body).to match '\"is_image\":true'
      end
    end

    context 'with valid non-image file' do
      before do
        post :create, 
          namespace_id: project.namespace.to_param,
          project_id: project.to_param, 
          file: txt, 
          format: :json
      end

      it 'returns a content with original filename, new link, and correct type.' do
        expect(response.body).to match '\"alt\":\"doc_sample.txt\"'
        expect(response.body).to match "\"url\":\"/uploads"
        expect(response.body).to match '\"is_image\":false'
      end
    end
  end

  describe "GET #show" do
    let(:go) do
      get :show,
        namespace_id: project.namespace.to_param,
        project_id:   project.to_param,
        secret:       "123456",
        filename:     "image.jpg"
    end

    context "when the project is public" do
      before do
        project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      context "when not signed in" do
        context "when the file exists" do
          before do
            allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
            allow(jpg).to receive(:exists?).and_return(true)
          end

          it "responds with status 200" do
            go

            expect(response.status).to eq(200)
          end
        end

        context "when the file doesn't exist" do
          it "responds with status 404" do
            go

            expect(response.status).to eq(404)
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the file exists" do
          before do
            allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
            allow(jpg).to receive(:exists?).and_return(true)
          end

          it "responds with status 200" do
            go

            expect(response.status).to eq(200)
          end
        end

        context "when the file doesn't exist" do
          it "responds with status 404" do
            go

            expect(response.status).to eq(404)
          end
        end
      end
    end

    context "when the project is private" do
      before do
        project.update_attribute(:visibility_level, Project::PRIVATE)
      end

      context "when not signed in" do
        context "when the file exists" do
          before do
            allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
            allow(jpg).to receive(:exists?).and_return(true)
          end

          context "when the file is an image" do
            before do
              allow_any_instance_of(FileUploader).to receive(:image?).and_return(true)
            end

            it "responds with status 200" do
              go

              expect(response.status).to eq(200)
            end
          end

          context "when the file is not an image" do
            it "redirects to the sign in page" do
              go

              expect(response).to redirect_to(new_user_session_path)
            end
          end
        end

        context "when the file doesn't exist" do
          it "redirects to the sign in page" do
            go

            expect(response).to redirect_to(new_user_session_path)
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user has access to the project" do
          before do
            project.team << [user, :master]
          end

          context "when the user is blocked" do
            before do
              user.block
              project.team << [user, :master]
            end

            context "when the file exists" do
              before do
                allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
                allow(jpg).to receive(:exists?).and_return(true)
              end

              context "when the file is an image" do
                before do
                  allow_any_instance_of(FileUploader).to receive(:image?).and_return(true)
                end

                it "responds with status 200" do
                  go

                  expect(response.status).to eq(200)
                end
              end

              context "when the file is not an image" do
                it "redirects to the sign in page" do
                  go

                  expect(response).to redirect_to(new_user_session_path)
                end
              end
            end

            context "when the file doesn't exist" do
              it "redirects to the sign in page" do
                go

                expect(response).to redirect_to(new_user_session_path)
              end
            end
          end

          context "when the user isn't blocked" do
            context "when the file exists" do
              before do
                allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
                allow(jpg).to receive(:exists?).and_return(true)
              end

              it "responds with status 200" do
                go

                expect(response.status).to eq(200)
              end
            end

            context "when the file doesn't exist" do
              it "responds with status 404" do
                go

                expect(response.status).to eq(404)
              end
            end
          end
        end

        context "when the user doesn't have access to the project" do
          context "when the file exists" do
            before do
              allow_any_instance_of(FileUploader).to receive(:file).and_return(jpg)
              allow(jpg).to receive(:exists?).and_return(true)
            end

            context "when the file is an image" do
              before do
                allow_any_instance_of(FileUploader).to receive(:image?).and_return(true)
              end

              it "responds with status 200" do
                go

                expect(response.status).to eq(200)
              end
            end

            context "when the file is not an image" do
              it "responds with status 404" do
                go

                expect(response.status).to eq(404)
              end
            end
          end

          context "when the file doesn't exist" do
            it "responds with status 404" do
              go

              expect(response.status).to eq(404)
            end
          end
        end
      end
    end
  end
end
