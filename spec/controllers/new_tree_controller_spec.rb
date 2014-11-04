require 'spec_helper'

require 'controllers/base_tree_controller'

describe Projects::NewTreeController do
  it_behaves_like Projects::BaseTreeController

  def edit_file_opts_base
    {
      id: existing_directory_id,
      file_name: new_file_name
    }
  end
end
