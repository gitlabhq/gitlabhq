require 'spec_helper'

describe NamespacesController do
  let!(:user) { create(:user, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }

  describe "GET show" do
    context "when the namespace belongs to a user" do
      let!(:other_user) { create(:user) }

      it "redirects to the user's page" do
        get :show, id: other_user.username

        expect(response).to redirect_to(user_path(other_user))
      end
    end

    context "when the namespace belongs to a group" do
      let!(:group)   { create(:group) }

      context "when the group is public" do
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

      context "when the group is private" do
        before do
          group.update_attribute(:visibility_level, Group::PRIVATE)
        end

        context "when not signed in" do
          it "redirects to the sign in page" do
            get :show, id: group.path
            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context "when signed in" do
          before do
            sign_in(user)
          end

          context "when the user has access to the group" do
            before do
              group.add_developer(user)
            end

            context "when the user is blocked" do
              before do
                user.block
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

          context "when the user doesn't have access to the group" do
            it "responds with status 404" do
              get :show, id: group.path

              expect(response).to have_http_status(404)
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

          expect(response).to have_http_status(404)
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
