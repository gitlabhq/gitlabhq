require 'spec_helper'

describe NamespacesController do
  let!(:user) { create(:user, :with_avatar) }

  describe "GET show" do
    context "when the namespace belongs to a user" do
      let!(:other_user) { create(:user) }

      it "redirects to the user's page" do
        get :show, id: other_user.username

        expect(response).to redirect_to(user_path(other_user))
      end
    end

    context "when the namespace belongs to a group" do
      let!(:group) { create(:group) }
      let!(:project) { create(:project, namespace: group) }

      context "when the group has public projects" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        context "when not signed in" do
          it "redirects to the group's page" do
            get :show, id: group.path

            expect(response).to redirect_to(group_path(group))
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          it "redirects to the group's page" do
            get :show, id: group.path

            expect(response).to redirect_to(group_path(group))
          end
        end
      end

      context "when the project doesn't have public projects" do
        context "when not signed in" do
          it "does not redirect to the sign in page" do
            get :show, id: group.path
            expect(response).not_to redirect_to(new_user_session_path)
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
                get :show, id: group.path

                expect(response).to redirect_to(new_user_session_path)
              end
            end

            context "when the user isn't blocked" do
              it "redirects to the group's page" do
                get :show, id: group.path

                expect(response).to redirect_to(group_path(group))
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "redirects to the group's page" do
              get :show, id: group.path

              expect(response).to redirect_to(group_path(group))
            end
          end
        end
      end
    end

    context "when the namespace doesn't exist" do
      context "when signed in" do
        before do
          sign_in(user)
        end

        it "responds with status 404" do
          get :show, id: "doesntexist"

          expect(response.status).to eq(404)
        end
      end

      context "when not signed in" do
        it "redirects to the sign in page" do
          get :show, id: "doesntexist"

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
