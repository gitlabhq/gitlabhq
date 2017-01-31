require 'spec_helper'

describe SnippetsFinder do
  let(:user) { create :user }
  let(:user1) { create :user }
  let(:group) { create :group, :public }

  let(:project1) { create(:empty_project, :public,  group: group) }
  let(:project2) { create(:empty_project, :private, group: group) }

  context ':all filter' do
    let!(:snippet1) { create(:personal_snippet, :private) }
    let!(:snippet2) { create(:personal_snippet, :internal) }
    let!(:snippet3) { create(:personal_snippet, :public) }

    it "returns all private and internal snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :all)

      expect(snippets).to include(snippet2, snippet3)
      expect(snippets).not_to include(snippet1)
    end

    it "returns all public snippets" do
      snippets = SnippetsFinder.new.execute(nil, filter: :all)

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end
  end

  context ':public filter' do
    let!(:snippet1) { create(:personal_snippet, :private) }
    let!(:snippet2) { create(:personal_snippet, :internal) }
    let!(:snippet3) { create(:personal_snippet, :public) }

    it "returns public public snippets" do
      snippets = SnippetsFinder.new.execute(nil, filter: :public)

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end
  end

  context ':by_user filter' do
    let!(:snippet1) { create(:personal_snippet, :private, author: user) }
    let!(:snippet2) { create(:personal_snippet, :internal, author: user) }
    let!(:snippet3) { create(:personal_snippet, :public, author: user) }

    it "returns all public and internal snippets" do
      snippets = SnippetsFinder.new.execute(user1, filter: :by_user, user: user)

      expect(snippets).to include(snippet2, snippet3)
      expect(snippets).not_to include(snippet1)
    end

    it "returns internal snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_internal")
      expect(snippets).to include(snippet2)
      expect(snippets).not_to include(snippet1, snippet3)
    end

    it "returns private snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_private")

      expect(snippets).to include(snippet1)
      expect(snippets).not_to include(snippet2, snippet3)
    end

    it "returns public snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_public")

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet1, snippet2)
    end

    it "returns all snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user)

      expect(snippets).to include(snippet1, snippet2, snippet3)
    end

    it "returns only public snippets if unauthenticated user" do
      snippets = SnippetsFinder.new.execute(nil, filter: :by_user, user: user)

      expect(snippets).to include(snippet3)
      expect(snippets).not_to include(snippet2, snippet1)
    end
  end

  context 'by_project filter' do
    before do
      @snippet1 = create(:project_snippet, :private,  project: project1)
      @snippet2 = create(:project_snippet, :internal, project: project1)
      @snippet3 = create(:project_snippet, :public,   project: project1)
    end

    it "returns public snippets for unauthorized user" do
      snippets = SnippetsFinder.new.execute(nil, filter: :by_project, project: project1)

      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end

    it "returns public and internal snippets for non project members" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)

      expect(snippets).to include(@snippet2, @snippet3)
      expect(snippets).not_to include(@snippet1)
    end

    it "returns public snippets for non project members" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1, scope: "are_public")

      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end

    it "returns internal snippets for non project members" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1, scope: "are_internal")

      expect(snippets).to include(@snippet2)
      expect(snippets).not_to include(@snippet1, @snippet3)
    end

    it "does not return private snippets for non project members" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1, scope: "are_private")

      expect(snippets).not_to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns all snippets for project members" do
      project1.team << [user, :developer]

      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns private snippets for project members" do
      project1.team << [user, :developer]

      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1, scope: "are_private")

      expect(snippets).to include(@snippet1)
    end

    it "returns all snippets for admin users" do
      user = create(:user, :admin)

      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns all snippets for auditor users" do
      user = create(:user, :auditor)

      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end
  end
end
