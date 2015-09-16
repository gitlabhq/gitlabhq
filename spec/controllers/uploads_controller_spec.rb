require 'spec_helper'

describe UploadsController do
  let!(:user) { create(:user, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }

  describe "GET show" do
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
            get :show, model: "user", mounted_as: "avatar", id: user.id, filename: "image.png"

            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context "when the user isn't blocked" do
          it "responds with status 200" do
            get :show, model: "user", mounted_as: "avatar", id: user.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end
      end
      
      context "when not signed in" do
        it "responds with status 200" do
          get :show, model: "user", mounted_as: "avatar", id: user.id, filename: "image.png"

          expect(response.status).to eq(200)
        end
      end
    end

    context "when viewing a project avatar" do
      let!(:project) { create(:project, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "redirects to the sign in page" do
            get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

            expect(response).to redirect_to(new_user_session_path)
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

              it "redirects to the sign in page" do
                get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

                expect(response.status).to eq(200)
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, model: "project", mounted_as: "avatar", id: project.id, filename: "image.png"

              expect(response.status).to eq(404)
            end
          end
        end
      end
    end

    context "when viewing a group avatar" do
      let!(:group) { create(:group, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }
      let!(:project) { create(:project, namespace: group) }

      context "when the group has public projects" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "responds with status 200" do
            get :show, model: "group", mounted_as: "avatar", id: group.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, model: "group", mounted_as: "avatar", id: group.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end
      end

      context "when the project doesn't have public projects" do
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

              it "redirects to the sign in page" do
                get :show, model: "group", mounted_as: "avatar", id: group.id, filename: "image.png"

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, model: "group", mounted_as: "avatar", id: group.id, filename: "image.png"

                expect(response.status).to eq(200)
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, model: "group", mounted_as: "avatar", id: group.id, filename: "image.png"

              expect(response.status).to eq(404)
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
            get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "responds with status 200" do
            get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

            expect(response.status).to eq(200)
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when not signed in" do
          it "redirects to the sign in page" do
            get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

            expect(response).to redirect_to(new_user_session_path)
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

              it "redirects to the sign in page" do
                get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

                expect(response.status).to eq(200)
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              get :show, model: "note", mounted_as: "attachment", id: note.id, filename: "image.png"

              expect(response.status).to eq(404)
            end
          end
        end
      end
    end
  end
end
