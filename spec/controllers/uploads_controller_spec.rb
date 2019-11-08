# frozen_string_literal: true

require 'spec_helper'
shared_examples 'content 5 min private cached with revalidation' do
  it 'ensures content will not be cached without revalidation' do
    expect(subject['Cache-Control']).to eq('max-age=300, private, must-revalidate')
  end
end

shared_examples 'content not cached' do
  it 'ensures content will not be cached without revalidation' do
    expect(subject['Cache-Control']).to eq('max-age=0, private, must-revalidate')
  end
end

shared_examples 'content publicly cached' do
  it 'ensures content is publicly cached' do
    expect(subject['Cache-Control']).to eq('max-age=300, public')
  end
end

describe UploadsController do
  include WorkhorseHelpers

  let!(:user) { create(:user, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

  describe 'POST #authorize' do
    it_behaves_like 'handle uploads authorize' do
      let(:uploader_class) { PersonalFileUploader }
      let(:model) { create(:personal_snippet, :public) }
      let(:params) do
        { model: 'personal_snippet', id: model.id }
      end
    end
  end

  describe 'POST create' do
    let(:jpg)     { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:txt)     { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }

    context 'snippet uploads' do
      let(:model)   { 'personal_snippet' }
      let(:snippet) { create(:personal_snippet, :public) }

      context 'when a user does not have permissions to upload a file' do
        it "returns 401 when the user is not logged in" do
          post :create, params: { model: model, id: snippet.id }, format: :json

          expect(response).to have_gitlab_http_status(401)
        end

        it "returns 404 when user can't comment on a snippet" do
          private_snippet = create(:personal_snippet, :private)

          sign_in(user)
          post :create, params: { model: model, id: private_snippet.id }, format: :json

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when a user is logged in' do
        before do
          sign_in(user)
        end

        it "returns an error without file" do
          post :create, params: { model: model, id: snippet.id }, format: :json

          expect(response).to have_gitlab_http_status(422)
        end

        it "returns an error with invalid model" do
          expect { post :create, params: { model: 'invalid', id: snippet.id }, format: :json }
            .to raise_error(ActionController::UrlGenerationError)
        end

        it "returns 404 status when object not found" do
          post :create, params: { model: model, id: 9999 }, format: :json

          expect(response).to have_gitlab_http_status(404)
        end

        context 'with valid image' do
          before do
            post :create, params: { model: 'personal_snippet', id: snippet.id, file: jpg }, format: :json
          end

          it 'returns a content with original filename, new link, and correct type.' do
            expect(response.body).to match '\"alt\":\"rails_sample\"'
            expect(response.body).to match "\"url\":\"/uploads"
          end

          it 'creates a corresponding Upload record' do
            upload = Upload.last

            aggregate_failures do
              expect(upload).to exist
              expect(upload.model).to eq snippet
            end
          end
        end

        context 'with valid non-image file' do
          before do
            post :create, params: { model: 'personal_snippet', id: snippet.id, file: txt }, format: :json
          end

          it 'returns a content with original filename, new link, and correct type.' do
            expect(response.body).to match '\"alt\":\"doc_sample.txt\"'
            expect(response.body).to match "\"url\":\"/uploads"
          end

          it 'creates a corresponding Upload record' do
            upload = Upload.last

            aggregate_failures do
              expect(upload).to exist
              expect(upload.model).to eq snippet
            end
          end
        end
      end
    end

    context 'user uploads' do
      let(:model) { 'user' }

      it 'returns 401 when the user has no access' do
        post :create, params: { model: 'user', id: user.id }, format: :json

        expect(response).to have_gitlab_http_status(401)
      end

      context 'when user is logged in' do
        before do
          sign_in(user)
        end

        subject do
          post :create, params: { model: model, id: user.id, file: jpg }, format: :json
        end

        it 'returns a content with original filename, new link, and correct type.' do
          subject

          expect(response.body).to match '\"alt\":\"rails_sample\"'
          expect(response.body).to match "\"url\":\"/uploads/-/system/user/#{user.id}/"
        end

        it 'creates a corresponding Upload record' do
          expect { subject }.to change { Upload.count }

          upload = Upload.last

          aggregate_failures do
            expect(upload).to exist
            expect(upload.model).to eq user
          end
        end

        context 'with valid non-image file' do
          subject do
            post :create, params: { model: model, id: user.id, file: txt }, format: :json
          end

          it 'returns a content with original filename, new link, and correct type.' do
            subject

            expect(response.body).to match '\"alt\":\"doc_sample.txt\"'
            expect(response.body).to match "\"url\":\"/uploads/-/system/user/#{user.id}/"
          end

          it 'creates a corresponding Upload record' do
            expect { subject }.to change { Upload.count }

            upload = Upload.last

            aggregate_failures do
              expect(upload).to exist
              expect(upload.model).to eq user
            end
          end
        end

        it 'returns 404 when given user is not the logged in one' do
          another_user = create(:user)

          post :create, params: { model: model, id: another_user.id, file: txt }, format: :json

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe "GET show" do
    context 'Content-Disposition security measures' do
      let(:project) { create(:project, :public) }

      context 'for PNG files' do
        it 'returns Content-Disposition: inline' do
          note = create(:note, :with_attachment, project: project)
          get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

          expect(response['Content-Disposition']).to start_with('inline;')
        end
      end

      context 'for SVG files' do
        it 'returns Content-Disposition: attachment' do
          note = create(:note, :with_svg_attachment, project: project)
          get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'unsanitized.svg' }

          expect(response['Content-Disposition']).to start_with('attachment;')
        end
      end
    end

    context "when viewing a user avatar" do
      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user is blocked" do
          before do
            user.block
          end

          it "redirects to the sign in page" do
            get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context "when the user isn't blocked" do
          it "responds with status 200" do
            get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'user', mounted_as: 'avatar', id: user.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when not signed in" do
        it "responds with status 200" do
          get :show, params: { model: "user", mounted_as: "avatar", id: user.id, filename: "dk.png" }

          expect(response).to have_gitlab_http_status(200)
        end

        it_behaves_like 'content publicly cached' do
          subject do
            get :show, params: { model: 'user', mounted_as: 'avatar', id: user.id, filename: 'dk.png' }

            response
          end
        end
      end
    end

    context "when viewing a project avatar" do
      let!(:project) { create(:project, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "redirects to the sign in page" do
            get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              project.add_maintainer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
                project.add_maintainer(user)
              end

              it "redirects to the sign in page" do
                get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content 5 min private cached with revalidation' do
                subject do
                  get :show, params: { model: 'project', mounted_as: 'avatar', id: project.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "project", mounted_as: "avatar", id: project.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context "when viewing a group avatar" do
      let!(:group) { create(:group, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

      context "when the group is public" do
        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content 5 min private cached with revalidation' do
            subject do
              get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the group is private" do
        before do
          group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              group.add_developer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
              end

              it "redirects to the sign in page" do
                get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content 5 min private cached with revalidation' do
                subject do
                  get :show, params: { model: 'group', mounted_as: 'avatar', id: group.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "group", mounted_as: "avatar", id: group.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context "when viewing a note attachment" do
      let!(:note) { create(:note, :with_attachment) }
      let(:project) { note.project }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content not cached' do
            subject do
              get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

              response
            end
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content not cached' do
            subject do
              get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "redirects to the sign in page" do
            get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the project" do
            before do
              project.add_maintainer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
                project.add_maintainer(user)
              end

              it "redirects to the sign in page" do
                get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

                expect(response).to have_gitlab_http_status(200)
              end

              it_behaves_like 'content not cached' do
                subject do
                  get :show, params: { model: 'note', mounted_as: 'attachment', id: note.id, filename: 'dk.png' }

                  response
                end
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, params: { model: "note", mounted_as: "attachment", id: note.id, filename: "dk.png" }

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end

    context 'Appearance' do
      context 'when viewing a custom header logo' do
        let!(:appearance) { create :appearance, header_logo: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

        context 'when not signed in' do
          it 'responds with status 200' do
            get :show, params: { model: 'appearance', mounted_as: 'header_logo', id: appearance.id, filename: 'dk.png' }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'appearance', mounted_as: 'header_logo', id: appearance.id, filename: 'dk.png' }

              response
            end
          end
        end
      end

      context 'when viewing a custom logo' do
        let!(:appearance) { create :appearance, logo: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

        context 'when not signed in' do
          it 'responds with status 200' do
            get :show, params: { model: 'appearance', mounted_as: 'logo', id: appearance.id, filename: 'dk.png' }

            expect(response).to have_gitlab_http_status(200)
          end

          it_behaves_like 'content publicly cached' do
            subject do
              get :show, params: { model: 'appearance', mounted_as: 'logo', id: appearance.id, filename: 'dk.png' }

              response
            end
          end
        end
      end
    end

    context 'original filename or a version filename must match' do
      let!(:appearance) { create :appearance, favicon: fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

      context 'has a valid filename on the original file' do
        it 'successfully returns the file' do
          get :show, params: { model: 'appearance', mounted_as: 'favicon', id: appearance.id, filename: 'dk.png' }

          expect(response).to have_gitlab_http_status(200)
          expect(response.header['Content-Disposition']).to end_with 'filename="dk.png"'
        end
      end

      context 'has an invalid filename on the original file' do
        it 'returns a 404' do
          get :show, params: { model: 'appearance', mounted_as: 'favicon', id: appearance.id, filename: 'bogus.png' }

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  def post_authorize(verified: true)
    request.headers.merge!(workhorse_internal_api_request_header) if verified

    post :authorize, params: { model: 'personal_snippet', id: model.id }, format: :json
  end
end
