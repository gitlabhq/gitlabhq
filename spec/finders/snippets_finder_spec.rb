require 'spec_helper'

describe SnippetsFinder do
  using RSpec::Parameterized::TableSyntax

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
    let(:user) { create :user }
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

    it "returns all snippets for 'are_internal' scope" do
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
    let(:user) { create :user }
    let(:user1) { create :user }
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
    let(:user) { create :user }
    let(:group) { create :group, :public }
    let(:project1) { create(:project, :public,  group: group) }

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
      project1.team << [user, :developer]

      snippets = described_class.new(user, project: project1).execute

      expect(snippets).to include(@snippet1, @snippet2, @snippet3)
    end

    it "returns private snippets for project members" do
      project1.team << [user, :developer]

      snippets = described_class.new(user, project: project1, visibility: Snippet::PRIVATE).execute

      expect(snippets).to include(@snippet1)
    end
  end

  describe "#execute" do
    context "with a given project" do
      let!(:users) do
        {
          unauthenticated: nil,
          external: create(:user),
          member: create(:user)
        }
      end

      let!(:project_types) do
        {
          public: create(:project, :public),
          internal: create(:project, :internal),
          private: create(:project, :private)
        }
      end

      let!(:snippets) do
        {
          public_project: {
            snippet_public: create(:project_snippet, :public, project: project_types[:public]),
            snippet_internal: create(:project_snippet, :internal, project: project_types[:public]),
            snippet_private: create(:project_snippet, :private, project: project_types[:public])
          },
          internal_project: {
            snippet_public: create(:project_snippet, :public, project: project_types[:internal]),
            snippet_internal: create(:project_snippet, :internal, project: project_types[:internal]),
            snippet_private: create(:project_snippet, :private, project: project_types[:internal])
          },
          private_project: {
            snippet_public: create(:project_snippet, :public, project: project_types[:private]),
            snippet_internal: create(:project_snippet, :internal, project: project_types[:private]),
            snippet_private: create(:project_snippet, :private, project: project_types[:private])
          }
        }
      end

      let(:project_feature_visibilities) do
        {
          enabled: 20,
          private: 10,
          disabled: 0
        }
      end

      where(:project_type, :feature_visibility, :current_user, :snippet_type, :outcome) do
        [
          # Public projects
          [:public, :enabled, :unauthenticated, :snippet_public,   true],
          [:public, :enabled, :unauthenticated, :snipet_internal,  false],
          [:public, :enabled, :unauthenticated, :snippet_private,  false],

          [:public, :enabled, :external,        :snippet_public,   true],
          [:public, :enabled, :external,        :snippet_internal, true],
          [:public, :enabled, :external,        :snippet_private,  false],

          [:public, :enabled, :member,          :snippet_public,   true],
          [:public, :enabled, :member,          :snippet_internal, true],
          [:public, :enabled, :member,          :snippet_private,  true],

          [:public, :private, :unauthenticated, :snippet_public,   false],
          [:public, :private, :unauthenticated, :snipet_internal,  false],
          [:public, :private, :unauthenticated, :snippet_private,  false],

          [:public, :private, :external,        :snippet_public,   false],
          [:public, :private, :external,        :snippet_internal, false],
          [:public, :private, :external,        :snippet_private,  false],

          [:public, :private, :member,          :snippet_public,   true],
          [:public, :private, :member,          :snippet_internal, true],
          [:public, :private, :member,          :snippet_private,  true],

          [:public, :disabled, :unauthenticated, :snippet_public,   false],
          [:public, :disabled, :unauthenticated, :snipet_internal,  false],
          [:public, :disabled, :unauthenticated, :snippet_private,  false],

          [:public, :disabled, :external,        :snippet_public,   false],
          [:public, :disabled, :external,        :snippet_internal, false],
          [:public, :disabled, :external,        :snippet_private,  false],

          [:public, :disabled, :member,          :snippet_public,   false],
          [:public, :disabled, :member,          :snippet_internal, false],
          [:public, :disabled, :member,          :snippet_private,  false],

          # Internal projects
          [:internal, :enabled, :unauthenticated, :snippet_public,   false],
          [:internal, :enabled, :unauthenticated, :snipet_internal,  false],
          [:internal, :enabled, :unauthenticated, :snippet_private,  false],

          [:internal, :enabled, :external,        :snippet_public,   true],
          [:internal, :enabled, :external,        :snippet_internal, true],
          [:internal, :enabled, :external,        :snippet_private,  false],

          [:internal, :enabled, :member,          :snippet_public,   true],
          [:internal, :enabled, :member,          :snippet_internal, true],
          [:internal, :enabled, :member,          :snippet_private,  true],

          [:internal, :private, :unauthenticated, :snippet_public,   false],
          [:internal, :private, :unauthenticated, :snipet_internal,  false],
          [:internal, :private, :unauthenticated, :snippet_private,  false],

          [:internal, :private, :external,        :snippet_public,   false],
          [:internal, :private, :external,        :snippet_internal, false],
          [:internal, :private, :external,        :snippet_private,  false],

          [:internal, :private, :member,          :snippet_public,   true],
          [:internal, :private, :member,          :snippet_internal, true],
          [:internal, :private, :member,          :snippet_private,  true],

          [:internal, :disabled, :unauthenticated, :snippet_public,   false],
          [:internal, :disabled, :unauthenticated, :snipet_internal,  false],
          [:internal, :disabled, :unauthenticated, :snippet_private,  false],

          [:internal, :disabled, :external,        :snippet_public,   false],
          [:internal, :disabled, :external,        :snippet_internal, false],
          [:internal, :disabled, :external,        :snippet_private,  false],

          [:internal, :disabled, :member,          :snippet_public,   false],
          [:internal, :disabled, :member,          :snippet_internal, false],
          [:internal, :disabled, :member,          :snippet_private,  false],

          # Private projects
          [:private, :enabled, :unauthenticated, :snippet_public,   false],
          [:private, :enabled, :unauthenticated, :snipet_internal,  false],
          [:private, :enabled, :unauthenticated, :snippet_private,  false],

          [:private, :enabled, :external,        :snippet_public,   false],
          [:private, :enabled, :external,        :snippet_internal, false],
          [:private, :enabled, :external,        :snippet_private,  false],

          [:private, :enabled, :member,          :snippet_public,   true],
          [:private, :enabled, :member,          :snippet_internal, true],
          [:private, :enabled, :member,          :snippet_private,  true],

          [:private, :private, :unauthenticated, :snippet_public,   false],
          [:private, :private, :unauthenticated, :snipet_internal,  false],
          [:private, :private, :unauthenticated, :snippet_private,  false],

          [:private, :private, :external,        :snippet_public,   false],
          [:private, :private, :external,        :snippet_internal, false],
          [:private, :private, :external,        :snippet_private,  false],

          [:private, :private, :member,          :snippet_public,   true],
          [:private, :private, :member,          :snippet_internal, true],
          [:private, :private, :member,          :snippet_private,  true],

          [:private, :disabled, :unauthenticated, :snippet_public,   false],
          [:private, :disabled, :unauthenticated, :snipet_internal,  false],
          [:private, :disabled, :unauthenticated, :snippet_private,  false],

          [:private, :disabled, :external,        :snippet_public,   false],
          [:private, :disabled, :external,        :snippet_internal, false],
          [:private, :disabled, :external,        :snippet_private,  false],

          [:private, :disabled, :member,          :snippet_public,   false],
          [:private, :disabled, :member,          :snippet_internal, false],
          [:private, :disabled, :member,          :snippet_private,  false]
        ]
      end

      with_them do
        context "For #{params[:project_type]} projects and #{params[:current_user]} users" do
          it 'should return proper outcome' do
            project = project_types[project_type]
            project.project_feature.update_attribute(:snippets_access_level, project_feature_visibilities[feature_visibility])
            user = users[current_user]
            project.team << [user, :developer] if current_user == :member

            results = described_class.new(user, project: project).execute
            snippet = snippets["#{project_type}_project".to_sym][snippet_type]
            expect(results.include?(snippet)).to eq(outcome)
          end
        end
      end
    end

    context 'without a given project' do
      let!(:author) { create(:user) }
      let!(:member) { create(:user) }
      let!(:public_project) { create(:project, :public) }
      let!(:internal_project) { create(:project, :internal) }
      let!(:private_project) { create(:project, :private) }

      let!(:users) do
        {
          unauthenticated: nil,
          external: create(:user),
          member: member,
          author: author
        }
      end

      let!(:members) do
        [member, author].each do |user_type|
          public_project.team << [user_type, :developer]
          internal_project.team << [user_type, :developer]
          private_project.team << [user_type, :developer]
        end
      end

      let!(:snippets) do
        {
          personal: {
            public: create(:personal_snippet, :public, author: author),
            internal: create(:personal_snippet, :internal, author: author),
            private: create(:personal_snippet, :private, author: author)
          },
          public_project: {
            public: create(:project_snippet, :public, author: author, project: public_project),
            internal: create(:project_snippet, :internal, author: author, project: public_project),
            private: create(:project_snippet, :private, author: author, project: public_project)
          },
          internal_project: {
            public: create(:project_snippet, :public, author: author, project: internal_project),
            internal: create(:project_snippet, :internal, author: author, project: internal_project),
            private: create(:project_snippet, :private, author: author, project: internal_project)
          },
          private_project: {
            public: create(:project_snippet, :public, author: author, project: private_project),
            internal: create(:project_snippet, :internal, author: author, project: private_project),
            private: create(:project_snippet, :private, author: author, project: private_project)
          }
        }
      end

      where(:snippet_type, :snippet_visibility, :current_user, :outcome) do
        [
          # Personal snippets
          [:personal,          :public,   :unauthenticated, true],
          [:personal,          :public,   :external,        true],
          [:personal,          :public,   :member,          true],
          [:personal,          :public,   :author,          true],

          [:personal,          :internal, :unauthenticated, false],
          [:personal,          :internal, :external,        true],
          [:personal,          :internal, :member,          true],
          [:personal,          :internal, :author,          true],

          [:personal,          :private,  :unauthenticated, false],
          [:personal,          :private,  :external,        false],
          [:personal,          :private,  :member,          false],
          [:personal,          :private,  :author,          true],

          # Snippets in a pu  blic project
          [:public_project,    :public,   :unauthenticated, true],
          [:public_project,    :public,   :external,        true],
          [:public_project,    :public,   :member,          true],
          [:public_project,    :public,   :author,          true],

          [:public_project,    :internal, :unauthenticated, false],
          [:public_project,    :internal, :external,        true],
          [:public_project,    :internal, :member,          true],
          [:public_project,    :internal, :author,          true],

          [:public_project,    :private,  :unauthenticated, false],
          [:public_project,    :private,  :external,        false],
          [:public_project,    :private,  :member,          true],
          [:public_project,    :private,  :author,          true],

          # Snippets in an internal project
          [:internal_project,  :public,   :unauthenticated, false],
          [:internal_project,  :public,   :external,        true],
          [:internal_project,  :public,   :member,          true],
          [:internal_project,  :public,   :author,          true],

          [:internal_project,  :internal, :unauthenticated, false],
          [:internal_project,  :internal, :external,        true],
          [:internal_project,  :internal, :member,          true],
          [:internal_project,  :internal, :author,          true],

          [:internal_project,  :private,  :unauthenticated, false],
          [:internal_project,  :private,  :external,        false],
          [:internal_project,  :private,  :member,          true],
          [:internal_project,  :private,  :author,          true],

          # Snippets in a private project
          [:private_project,   :public,   :unauthenticated, false],
          [:private_project,   :public,   :external,        false],
          [:private_project,   :public,   :member,          true],
          [:private_project,   :public,   :author,          true],

          [:private_project,   :internal, :unauthenticated, false],
          [:private_project,   :internal, :external,        false],
          [:private_project,   :internal, :member,          true],
          [:private_project,   :internal, :author,          true],

          [:private_project,   :private,  :unauthenticated, false],
          [:private_project,   :private,  :external,        false],
          [:private_project,   :private,  :member,          true],
          [:private_project,   :private,  :author,          true]
        ]
      end

      with_them do
        context "For #{params[:snippet_type]} and #{params[:snippet_visibility]} snippets with #{params[:current_user]} user" do
          it 'should return proper outcome' do
            user = users[current_user]

            results = described_class.new(user).execute
            snippet = snippets[snippet_type][snippet_visibility]
            expect(results.include?(snippet)).to eq(outcome)
          end
        end
      end
    end
  end
end
