require 'spec_helper'

describe "Internal Project Snippets Access", feature: true  do
  include AccessMatchers

  let(:project) { create(:empty_project, :internal) }

  let(:owner)     { project.owner }
  let(:master)    { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter)  { create(:user) }
  let(:guest)     { create(:user) }
  let(:internal_snippet) { create(:project_snippet, :internal, project: project, author: owner) }
  let(:private_snippet)  { create(:project_snippet, :private, project: project, author: owner) }

  before do
    project.team << [master, :master]
    project.team << [developer, :developer]
    project.team << [reporter, :reporter]
    project.team << [guest, :guest]
  end

  describe "GET /:project_path/snippets" do
    subject { namespace_project_snippets_path(project.namespace, project) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/snippets/new" do
    subject { new_namespace_project_snippet_path(project.namespace, project) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe "GET /:project_path/snippets/:id" do
    context "for an internal snippet" do
      subject { namespace_project_snippet_path(project.namespace, project, internal_snippet) }

      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for developer }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :external }
      it { is_expected.to be_denied_for :visitor }
    end

    context "for a private snippet" do
      subject { namespace_project_snippet_path(project.namespace, project, private_snippet) }

      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for developer }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :external }
      it { is_expected.to be_denied_for :visitor }
    end
  end

  describe "GET /:project_path/snippets/:id/raw" do
    context "for an internal snippet" do
      subject { raw_namespace_project_snippet_path(project.namespace, project, internal_snippet) }

      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for developer }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :external }
      it { is_expected.to be_denied_for :visitor }
    end

    context "for a private snippet" do
      subject { raw_namespace_project_snippet_path(project.namespace, project, private_snippet) }

      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for developer }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :external }
      it { is_expected.to be_denied_for :visitor }
    end
  end
end
