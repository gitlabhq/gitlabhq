require 'spec_helper'

describe "Internal Project Snippets Access"  do
  include AccessMatchers

  let(:project) { create(:project, :internal) }

  let(:internal_snippet) { create(:project_snippet, :internal, project: project, author: project.owner) }
  let(:private_snippet)  { create(:project_snippet, :private,  project: project, author: project.owner) }

  describe "GET /:project_path/snippets" do
    subject { project_snippets_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:master).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_project_snippet_path(project) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:master).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_denied_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path/snippets/:id" do
    context "for an internal snippet" do
      subject { project_snippet_path(project, internal_snippet) }

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:master).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_allowed_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    context "for a private snippet" do
      subject { project_snippet_path(project, private_snippet) }

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:master).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end

  describe "GET /:project_path/snippets/:id/raw" do
    context "for an internal snippet" do
      subject { raw_project_snippet_path(project, internal_snippet) }

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:master).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_allowed_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    context "for a private snippet" do
      subject { raw_project_snippet_path(project, private_snippet) }

      it { is_expected.to be_allowed_for(:admin) }
      it { is_expected.to be_allowed_for(:owner).of(project) }
      it { is_expected.to be_allowed_for(:master).of(project) }
      it { is_expected.to be_allowed_for(:developer).of(project) }
      it { is_expected.to be_allowed_for(:reporter).of(project) }
      it { is_expected.to be_allowed_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:external) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end
end
