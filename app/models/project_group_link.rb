#-------------------------------------------------------------------
#
# The GitLab Enterprise Edition (EE) license
#
# Copyright (c) 2013 GitLab.com
#
# All Rights Reserved. No part of this software may be reproduced without
# prior permission of GitLab.com. By using this software you agree to be
# bound by the GitLab Enterprise Support Subscription Terms.
#
#-------------------------------------------------------------------

class ProjectGroupLink < ActiveRecord::Base
  belongs_to :project
  belongs_to :group

  validates :project_id, presence: true
  validates :group_id, presence: true
  validates :group_id, uniqueness: { scope: [:project_id], message: "already shared with this group" }
end
