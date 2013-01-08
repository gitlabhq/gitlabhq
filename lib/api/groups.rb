module Gitlab
  # groups API
  class Groups < Grape::API
    before { authenticate! }
   
       resource :groups do
         # Get a groups list
         #
         # Example Request:
         #  GET /groups
         get do
           @groups = paginate Group
           present @groups, with: Entities::Group

         end
         
         # Create group. Available only for admin
         #
         # Parameters:
         #   name (required)                   - Name
         #   path (required)                   - Path
         # Example Request:
         #   POST /groups
         post do
           authenticated_as_admin!
           attrs = attributes_for_keys [:name, :path]
           @group = Group.new(attrs)
           @group.owner = current_user
           
           if @group.save
             present @group, with: Entities::Group
           else
             not_found!
           end
         end
         
         # Get a single group, with containing projects
         #
         # Parameters:
         #   id (required) - The ID of a group
         # Example Request:
         #   GET /groups/:id
         get ":id" do
           @group = Group.find(params[:id])
           present @group, with: Entities::GroupDetail
         end
         
       end
  end
end
