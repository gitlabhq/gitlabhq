require 'spec_helper'

describe SnippetsFinder do
  let(:user) { create :user }
  let(:user1) { create :user }
  let(:group) { create :group, :public }

  let(:project1) { create(:project, :public,  group: group) }
  let(:project2) { create(:project, :private, group: group) }

  context 'all snippets visible to a user' do
    let!(:snippet1) { create(:personal_snippet, :private) }
    let!(:snippet2) { create(:personal_snippet, :internal) }
    let!(:snippet3) { create(:personal_snippet, :public) }
    let!(:project_snippet1) { create(:project_snippet, :private) }
    let!(:project_snippet2) { create(:project_snippet, :internal) }
    let!(:project_snippet3) { create(:project_snippet, :public) }

    it "returns all private and internal snippets" do
      snippets = described_class.new(user, scope: :all).execute
      expect(snippets).to include(snippet2, snippet3, project_snippet2, project_snippet3)
      expect(snippets).not_to include(snippet1, project_snippet1)
    end

    it "returns all public snippets" do
      snippets = described_class.new(nil, scope: :all).execute
      expect(snippets).to include(snippet3, project_snippet3)
      expect(snippets).not_to include(snippet1, snippet2, project_snippet1, project_snippet2)
    end

    it "returns all public and internal snippets for normal user" do
      snippets = described_class.new(user).execute

      expect(snippets).to include(snippet2, snippet3, project_snippet2, project_snippet3)
      expect(snippets).not_to include(snippet1, project_snippet1)
    end

    it "returns all public snippets for non authorized user" do
      snippets = described_class.new(nil).execute

      expect(snippets).to include(snippet3, project_snippet3)
      expect(snippets).not_to include(snippet1, snippet2, project_snippet1, project_snippet2)
    end

    it "returns all public and authored snippets for external user" do
      external_user = create(:user, :external)
      authored_snippet = create(:personal_snippet, :internal, author: external_user)

      snippets = described_class.new(external_user).execute

      expect(snippets).to include(snippet3, project_snippet3, authored_snippet)
      expect(snippets).not_to include(snippet1, snippet2, project_snippet1, project_snippet2)
    end
  end

  context 'filter by visibility' do
    let!(:snippet1) { create(:personal_snippet, :private) }
    let!(:snippet2) { create(:personal_snippet, :internal) }
    let!(:snippet3) { create(:personal_snippet, :public) }

    it "returns public snippets when visibility is PUBLIC" do
      snippets = described_class.new(nil, visibility: Snippet::PUBLIC).execute

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end
  end

  context 'filter by scope' do
    let!(:snippet1) { create(:personal_snippet, :private, author: user) }
    let!(:snippet2) { create(:personal_snippet, :internal, author: user) }
    let!(:snippet3) { create(:personal_snippet, :public, author: user) }

    it "returns all snippets for 'all' scope" do
      snippets = described_class.new(user, scope: :all).execute

      expect(snippets).to include(snippet1, snippet2, snippet3)
    end

    it "returns all snippets for 'are_private' scope" do
      snippets = described_class.new(user, scope: :are_private).execute

      expect(snippets).to include(snippet1)
      expect(snippets).not_to include(snippet2, snippet3)
    end

    it "returns all snippets for 'are_interna;' scope" do
      snippets = described_class.new(user, scope: :are_internal).execute

      expect(snippets).to include(snippet2)
      expect(snippets).not_to include(snippet1, snippet3)
    end

    it "returns all snippets for 'are_private' scope" do
      snippets = described_class.new(user, scope: :are_public).execute

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end
  end

  context 'filter by author' do
    let!(:snippet1) { create(:personal_snippet, :private, author: user) }
    let!(:snippet2) { create(:personal_snippet, :internal, author: user) }
    let!(:snippet3) { create(:personal_snippet, :public, author: user) }

    it "returns all public and internal snippets" do
      snippets = described_class.new(user1, author: user).execute

      expect(snippets).to include(snippet2, snippet3)
      expect(snippets).not_to include(snippet1)
    end

    it "returns internal snippets" do
      snippets = described_class.new(user, author: user, visibility: Snippet::INTERNAL).execute

      expect(snippets).to include(snippet2)
      expect(snippets).not_to include(snippet1, snippet3)
    end

    it "returns private snippets" do
      snippets = described_class.new(user, author: user, visibility: Snippet::PRIVATE).execute

      expect(snippets).to include(snippet1)
      expect(snippets).not_to include(snippet2, snippet3)
    end

    it "returns public snippets" do
      snippets = described_class.new(user, author: user, visibility: Snippet::PUBLIC).execute

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end

    it "returns all snippets" do
      snippets = described_class.new(user, author: user).execute

      expect(snippets).to include(snippet1, snippet2, snippet3)
    end

    it "returns only public snippets if unauthenticated user" do
      snippets = described_class.new(nil, author: user).execute

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet2, snippet1)
    end
  end

  context 'filter by project' do
    before do
      @snippet1 = create(:project_snippet, :private,  project: project1)
      @snippet2 = create(:project_snippet, :internal, project: project1)
      @snippet3 = create(:project_snippet, :public,   project: project1)
    end

    it "returns public snippets for unauthorized user" do
      snippets = described_class.new(nil, project: project1).execute

      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end

    it "returns public and internal snippets for non project members" do
      snippets = described_class.new(user, project: project1).execute

      expect(snippets).to include(@snippet2, @snippet3)
      expect(snippets).not_to include(@snippet1)
    end

    it "returns public snippets for non project members" do
      snippets = described_class.new(user, project: project1, visibility: Snippet::PUBLIC).execute

      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end

    it "returns internal snippets for non project members" do
      snippets = described_class.new(user, project: project1, visibility: Snippet::INTERNAL).execute

      expect(snippets).to include(@snippet2)
      expect(snippets).not_to include(@snippet1, @snippet3)
    end

    it "does not return private snippets for non project members" do
      snippets = described_class.new(user, project: project1, visibility: Snippet::PRIVATE).execute

      expect(snippets).not_to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns all snippets for project members" do
      project1.add_developer(user)

      snippets = described_class.new(user, project: project1).execute

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns private snippets for project members" do
      project1.add_developer(user)

      snippets = described_class.new(user, project: project1, visibility: Snippet::PRIVATE).execute

      expect(snippets).to include(@snippet1)
    end

    it "returns all snippets for admin users" do
      user = create(:user, :admin)

      snippets = described_class.new(user, project: project1).execute

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns all snippets for auditor users" do
      user = create(:user, :auditor)

      snippets = described_class.new(user, project: project1).execute

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end
  end
end
