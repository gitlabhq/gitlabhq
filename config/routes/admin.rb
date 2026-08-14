# frozen_string_literal: true

# `/admin/*` is instance administration and must be excluded from the
# organization scope. `/o/:organization_path/admin` is organization
# administration (including the default organization).
if @organization_scoped_routes
  draw_all :organization_admin
else
  draw_all :instance_admin
end
