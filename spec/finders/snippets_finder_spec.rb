require 'spec_helper'

describe SnippetsFinder do
  let(:user) { create :user }
  let(:user1) { create :user }
  let(:group) { create :group }

  let(:project1) { create(:empty_project, :public,  group: group) }
  let(:project2) { create(:empty_project, :private, group: group) }

  context ':all filter' do
    before do
      @snippet1 = create(:personal_snippet, :private)
      @snippet2 = create(:personal_snippet, :internal)
      @snippet3 = create(:personal_snippet, :public)
    end

    it "returns all private and internal snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :all)
      expect(snippets).to include(@snippet2, @snippet3)
      expect(snippets).not_to include(@snippet1)
    end

    it "returns all public snippets" do
      snippets = SnippetsFinder.new.execute(nil, filter: :all)
      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end
  end

  context ':by_user filter' do
    before do
      @snippet1 = create(:personal_snippet, :private,  author: user)
      @snippet2 = create(:personal_snippet, :internal, author: user)
      @snippet3 = create(:personal_snippet, :public,   author: user)
    end

    it "returns all public and internal snippets" do
      snippets = SnippetsFinder.new.execute(user1, filter: :by_user, user: user)
      expect(snippets).to include(@snippet2, @snippet3)
      expect(snippets).not_to include(@snippet1)
    end

    it "returns internal snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_internal")
      expect(snippets).to include(@snippet2)
      expect(snippets).not_to include(@snippet1, @snippet3)
    end

    it "returns private snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_private")
      expect(snippets).to include(@snippet1)
      expect(snippets).not_to include(@snippet2, @snippet3)
    end

    it "returns public snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user, scope: "are_public")
      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet1, @snippet2)
    end

    it "returns all snippets" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_user, user: user)
      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns only public snippets if unauthenticated user" do
      snippets = SnippetsFinder.new.execute(nil, filter: :by_user, user: user)
      expect(snippets).to include(@snippet3)
      expect(snippets).not_to include(@snippet2, @snippet1)
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

    it "returns public and internal snippets for none project members" do
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)
      expect(snippets).to include(@snippet2, @snippet3)
      expect(snippets).not_to include(@snippet1)
    end

    it "returns all snippets for project members" do
      project1.team << [user, :developer]
      snippets = SnippetsFinder.new.execute(user, filter: :by_project, project: project1)
      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end
  end
end
