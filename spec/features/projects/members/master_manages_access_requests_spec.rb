# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Maintainer manages access requests' do
  it_behaves_like 'Maintainer manages access requests' do
    let(:entity) { create(:project, :public, :access_requestable) }
    let(:members_page_path) { project_project_members_path(entity) }
  end
end
