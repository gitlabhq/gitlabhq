# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Private Project Snippets Access", feature_category: :system_access do
  include AccessMatchers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:private_snippet) { create(:project_snippet, :private, project: project, author: project.first_owner) }

  describe "GET /:project_path/snippets" do
    subject { project_snippets_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }

    specify :aggregate_failures do
      is_expected.to be_allowed_for(:owner).of(project)
      is_expected.to be_allowed_for(:maintainer).of(project)
      is_expected.to be_allowed_for(:developer).of(project)
      is_expected.to be_allowed_for(:reporter).of(project)
      is_expected.to be_allowed_for(:guest).of(project)
      is_expected.to be_denied_for(:user)
      is_expected.to be_denied_for(:external)
      is_expected.to be_denied_for(:visitor)
    end
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_project_snippet_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }

    specify :aggregate_failures do
      is_expected.to be_allowed_for(:maintainer).of(project)
      is_expected.to be_allowed_for(:owner).of(project)
      is_expected.to be_allowed_for(:developer).of(project)
      is_expected.to be_allowed_for(:reporter).of(project)
      is_expected.to be_denied_for(:guest).of(project)
      is_expected.to be_denied_for(:user)
      is_expected.to be_denied_for(:external)
      is_expected.to be_denied_for(:visitor)
    end
  end

  describe "GET /:project_path/snippets/:id for a private snippet" do
    subject { project_snippet_path(project, private_snippet) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }

    specify :aggregate_failures do
      is_expected.to be_allowed_for(:owner).of(project)
      is_expected.to be_allowed_for(:maintainer).of(project)
      is_expected.to be_allowed_for(:developer).of(project)
      is_expected.to be_allowed_for(:reporter).of(project)
      is_expected.to be_allowed_for(:guest).of(project)
      is_expected.to be_denied_for(:user)
      is_expected.to be_denied_for(:external)
      is_expected.to be_denied_for(:visitor)
    end
  end

  describe "GET /:project_path/snippets/:id/raw for a private snippet" do
    subject { raw_project_snippet_path(project, private_snippet) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }

    specify :aggregate_failures do
      is_expected.to be_allowed_for(:owner).of(project)
      is_expected.to be_allowed_for(:maintainer).of(project)
      is_expected.to be_allowed_for(:developer).of(project)
      is_expected.to be_allowed_for(:reporter).of(project)
      is_expected.to be_allowed_for(:guest).of(project)
      is_expected.to be_denied_for(:user)
      is_expected.to be_denied_for(:external)
      is_expected.to be_denied_for(:visitor)
    end
  end
end
