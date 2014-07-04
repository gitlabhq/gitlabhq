require 'spec_helper'

require 'controllers/base_tree_controller'

describe Projects::EditTreeController do
  def edit_file_opts_base
    { id: existing_file_id }
  end

  shared_examples 'unchanged content' do
    it 'fails, stays on edit page and does not create a branch '\
       "if the content wasn't changed" do
      expect(project.repository).not_to have_branch(valid_new_branch_name)

      make_new_mr(content: old_content)

      expect(project.repository).not_to have_branch(valid_new_branch_name)
      expect(flash['alert']).not_to be_nil
      expect(response).to be_success
    end
  end

  it_behaves_like Projects::BaseTreeController
end
