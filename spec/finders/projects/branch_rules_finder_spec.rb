# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRulesFinder, feature_category: :source_code_management, type: :model do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:all_branches_rule) { Projects::AllBranchesRule.new(project) }
  let_it_be(:custom_rules) { [all_branches_rule] }

  let(:protected_branches) { project.protected_branches.sorted_by_name }
  let(:finder) do
    described_class.new(project, custom_rules: custom_rules, protected_branches: protected_branches)
  end

  describe '#execute' do
    subject(:page) { finder.execute(cursor: cursor, limit: limit) }

    let(:cursor) { nil }
    let(:limit) { 20 }

    it 'returns a page struct with expected attributes' do
      expect(page).to be_a(described_class::Page)
      expect(page).to respond_to(:rules, :end_cursor, :has_next_page)
    end

    describe 'limit parameter' do
      context 'when limit is nil' do
        let(:limit) { nil }

        it 'defaults to 20' do
          create_list(:protected_branch, 25, project: project) # rubocop:disable FactoryBot/ExcessiveCreateList -- Needed for testing page size

          expect(page.rules.size).to eq(20)
        end
      end

      context 'when limit is 1' do
        let(:limit) { 1 }

        it 'returns only one rule' do
          create_list(:protected_branch, 5, project: project)

          expect(page.rules.size).to eq(1)
          expect(page.has_next_page).to be true
        end
      end
    end

    context 'with no protected branches' do
      context 'when limit is greater than custom rules count' do
        let(:limit) { 20 }

        it 'returns only custom rules' do
          expect(page.rules).to eq(custom_rules)
          expect(page.has_next_page).to be false
          expect(page.end_cursor).to be_nil
        end
      end

      context 'when limit equals custom rules count' do
        let(:limit) { 1 }

        it 'returns all custom rules with no next page' do
          expect(page.rules).to eq(custom_rules)
          expect(page.has_next_page).to be false
        end
      end

      context 'when limit is less than custom rules count' do
        let(:custom_rule_2) { Projects::AllBranchesRule.new(project) }
        let(:custom_rules) { [all_branches_rule, custom_rule_2] }
        let(:limit) { 1 }

        it 'returns partial custom rules with next page' do
          expect(page.rules.size).to eq(1)
          expect(page.rules.first).to eq(all_branches_rule)
          expect(page.has_next_page).to be true
          expect(page.end_cursor).to be_present
        end
      end
    end

    context 'with protected branches' do
      let!(:protected_branch_a) { create(:protected_branch, project: project, name: 'abranch') }
      let!(:protected_branch_b) { create(:protected_branch, project: project, name: 'bbranch') }
      let!(:protected_branch_c) { create(:protected_branch, project: project, name: 'cbranch') }

      describe 'first page' do
        context 'when limit is greater than total rules' do
          let(:limit) { 20 }

          it 'returns all custom rules and all protected branches' do
            expect(page.rules.size).to eq(4)
            expect(page.rules.first).to eq(all_branches_rule)
            expect(page.rules[3].protected_branch).to eq(protected_branch_c)
            expect(page.has_next_page).to be false
            expect(page.end_cursor).to be_nil
          end
        end

        context 'when limit equals custom rules count' do
          let(:limit) { 1 }

          it 'returns only custom rules with next page' do
            expect(page.rules.size).to eq(1)
            expect(page.rules.first).to eq(all_branches_rule)
            expect(page.has_next_page).to be true
            expect(page.end_cursor).to be_present
          end
        end

        context 'when limit is between custom rules and total rules' do
          let(:limit) { 2 }

          it 'returns custom rules and some protected branches' do
            expect(page.rules.size).to eq(2)
            expect(page.rules.first).to eq(all_branches_rule)
            expect(page.rules.last.protected_branch).to eq(protected_branch_a)
            expect(page.has_next_page).to be true
            expect(page.end_cursor).to be_present
          end
        end
      end

      describe 'after custom rule cursor' do
        let(:cursor) { encode_cursor('all_branches') }
        let(:limit) { 2 }

        it 'returns protected branches' do
          expect(page.rules.size).to eq(2)
          expect(page.rules.first.protected_branch).to eq(protected_branch_a)
          expect(page.rules.last.protected_branch).to eq(protected_branch_b)
          expect(page.has_next_page).to be true
        end
      end

      describe 'after protected branch cursor' do
        let(:cursor) { encode_cursor(protected_branch_a.name, protected_branch_a.id) }
        let(:limit) { 2 }

        it 'returns next protected branches' do
          expect(page.rules.size).to eq(2)
          expect(page.rules.first.protected_branch).to eq(protected_branch_b)
          expect(page.rules.last.protected_branch).to eq(protected_branch_c)
          expect(page.has_next_page).to be false
        end

        context 'when on last page' do
          let(:cursor) { encode_cursor(protected_branch_b.name, protected_branch_b.id) }
          let(:limit) { 20 }

          it 'returns remaining rules with no next page' do
            expect(page.rules.size).to eq(1)
            expect(page.rules.first.protected_branch).to eq(protected_branch_c)
            expect(page.has_next_page).to be false
            expect(page.end_cursor).to be_nil
          end
        end
      end
    end

    context 'with many protected branches' do
      before do
        ('a'..'x').each do |letter|
          create(:protected_branch, project: project, name: "branch-#{letter}")
        end
      end

      it 'paginates correctly through all pages' do
        first_page = finder.execute(cursor: nil, limit: 20)
        expect(first_page.rules.size).to eq(20)
        expect(first_page.has_next_page).to be true
        expect(first_page.rules.first).to eq(all_branches_rule)

        second_page = finder.execute(cursor: first_page.end_cursor, limit: 20)
        expect(second_page.rules.size).to eq(5)
        expect(second_page.has_next_page).to be false
        expect(second_page.end_cursor).to be_nil
      end

      it 'maintains correct order across pages' do
        first_page = finder.execute(cursor: nil, limit: 10)
        second_page = finder.execute(cursor: first_page.end_cursor, limit: 10)

        # Verify that there are no duplicates
        all_rule_names = (first_page.rules + second_page.rules).map(&:name)
        expect(all_rule_names.uniq.size).to eq(all_rule_names.size)
      end
    end

    describe 'keyset pagination correctness' do
      context 'when alphabetical order differs from ID order' do
        let!(:branch_z) { create(:protected_branch, project: project, name: 'z-branch') }
        let!(:branch_a) { create(:protected_branch, project: project, name: 'a-branch') }
        let!(:branch_m) { create(:protected_branch, project: project, name: 'm-branch') }

        it 'orders by name alphabetically' do
          page = finder.execute(cursor: nil, limit: 20)

          expect(page.rules.map(&:name)).to eq(['All branches', 'a-branch', 'm-branch', 'z-branch'])
        end

        it 'paginates correctly with cursor' do
          cursor = encode_cursor(branch_a.name, branch_a.id)
          page = finder.execute(cursor: cursor, limit: 20)

          expect(page.rules.map(&:name)).to eq(%w[m-branch z-branch])
        end
      end
    end

    context 'for cursor edge cases' do
      let!(:protected_branch) { create(:protected_branch, project: project, name: 'main') }

      it 'raises error for invalid cursor' do
        expect { finder.execute(cursor: Base64.strict_encode64('invalid-cursor'), limit: 20) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Invalid cursor/)
      end

      it 'raises error for malformed base64 cursor' do
        expect { finder.execute(cursor: 'not-base64!!!', limit: 20) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Invalid cursor/)
      end

      it 'handles non-existent custom rule cursor' do
        cursor = encode_cursor('Non-existent rule')
        page = finder.execute(cursor: cursor, limit: 20)

        expect(page.rules.first.protected_branch).to eq(protected_branch)
      end

      it 'returns empty page when cursor points past the last result' do
        cursor = encode_cursor(protected_branch.name, protected_branch.id)
        page = finder.execute(cursor: cursor, limit: 20)

        expect(page.rules).to be_empty
        expect(page.has_next_page).to be false
        expect(page.end_cursor).to be_nil
      end

      it 'handles special characters in branch names' do
        branch = create(:protected_branch, project: project, name: 'feature/test:123')
        cursor = encode_cursor(branch.name, branch.id)

        expect { finder.execute(cursor: cursor, limit: 20) }.not_to raise_error
      end

      context 'when protected branch name matches custom rule identifier' do
        let!(:branch_aaa) { create(:protected_branch, project: project, name: 'aaa') }
        let!(:branch_all_branches) { create(:protected_branch, project: project, name: 'all_branches') }
        let!(:branch_zzz) { create(:protected_branch, project: project, name: 'zzz') }
        let(:cursor) { encode_cursor('all_branches', branch_all_branches.id) }

        it 'paginates correctly when protected branch has same name as custom rule' do
          expect(page.rules.map(&:name)).to include('zzz')
          expect(page.rules.map(&:name)).not_to include('aaa', 'all_branches')
        end
      end
    end
  end

  describe '#identifier_for_rule' do
    it 'returns nil when rule is nil' do
      expect(finder.send(:identifier_for_rule, nil)).to be_nil
    end

    it 'returns ALL_BRANCHES_IDENTIFIER for AllBranchesRule' do
      expect(finder.send(:identifier_for_rule, all_branches_rule)).to eq('all_branches')
    end

    it 'returns nil for non-custom rules' do
      protected_branch = create(:protected_branch, project: project)
      branch_rule = Projects::BranchRule.new(project, protected_branch)

      expect(finder.send(:identifier_for_rule, branch_rule)).to be_nil
    end
  end

  describe '#encode_cursor' do
    it 'returns nil when name is nil' do
      expect(finder.send(:encode_cursor, nil, 123)).to be_nil
    end

    it 'encodes cursor with name and id' do
      cursor = finder.send(:encode_cursor, 'test', 123)
      decoded = Gitlab::Json.parse(Base64.strict_decode64(cursor))

      expect(decoded).to eq({ 'name' => 'test', 'id' => 123 })
    end

    it 'encodes cursor with name only' do
      cursor = finder.send(:encode_cursor, 'test')
      decoded = Gitlab::Json.parse(Base64.strict_decode64(cursor))

      expect(decoded).to eq({ 'name' => 'test', 'id' => nil })
    end
  end

  def encode_cursor(name, id = nil)
    return unless name

    cursor = { name: name, id: id }.to_json
    Base64.strict_encode64(cursor)
  end
end
