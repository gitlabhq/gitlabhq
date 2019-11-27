# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::IssuesResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }

  context "with a project" do
    set(:project) { create(:project) }
    set(:issue1) { create(:issue, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago) }
    set(:issue2) { create(:issue, project: project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }
    set(:label1) { create(:label, project: project) }
    set(:label2) { create(:label, project: project) }

    before do
      project.add_developer(current_user)
      create(:label_link, label: label1, target: issue1)
      create(:label_link, label: label1, target: issue2)
      create(:label_link, label: label2, target: issue2)
    end

    describe '#resolve' do
      it 'finds all issues' do
        expect(resolve_issues).to contain_exactly(issue1, issue2)
      end

      it 'filters by state' do
        expect(resolve_issues(state: 'opened')).to contain_exactly(issue1)
        expect(resolve_issues(state: 'closed')).to contain_exactly(issue2)
      end

      it 'filters by labels' do
        expect(resolve_issues(label_name: [label1.title])).to contain_exactly(issue1, issue2)
        expect(resolve_issues(label_name: [label1.title, label2.title])).to contain_exactly(issue2)
      end

      describe 'filters by created_at' do
        it 'filters by created_before' do
          expect(resolve_issues(created_before: 2.hours.ago)).to contain_exactly(issue1)
        end

        it 'filters by created_after' do
          expect(resolve_issues(created_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      describe 'filters by updated_at' do
        it 'filters by updated_before' do
          expect(resolve_issues(updated_before: 2.hours.ago)).to contain_exactly(issue1)
        end

        it 'filters by updated_after' do
          expect(resolve_issues(updated_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      describe 'filters by closed_at' do
        let!(:issue3) { create(:issue, project: project, state: :closed, closed_at: 3.hours.ago) }

        it 'filters by closed_before' do
          expect(resolve_issues(closed_before: 2.hours.ago)).to contain_exactly(issue3)
        end

        it 'filters by closed_after' do
          expect(resolve_issues(closed_after: 2.hours.ago)).to contain_exactly(issue2)
        end
      end

      context 'when searching issues' do
        it 'returns correct issues' do
          expect(resolve_issues(search: 'foo')).to contain_exactly(issue2)
        end

        it 'uses project search optimization' do
          expected_arguments = {
            search: 'foo',
            attempt_project_search_optimizations: true,
            iids: [],
            project_id: project.id
          }
          expect(IssuesFinder).to receive(:new).with(anything, expected_arguments).and_call_original

          resolve_issues(search: 'foo')
        end
      end

      describe 'sorting' do
        context 'when sorting by created' do
          it 'sorts issues ascending' do
            expect(resolve_issues(sort: 'created_asc')).to eq [issue1, issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: 'created_desc')).to eq [issue2, issue1]
          end
        end

        context 'when sorting by due date' do
          let(:project) { create(:project) }

          let!(:due_issue1) { create(:issue, project: project, due_date: 3.days.from_now) }
          let!(:due_issue2) { create(:issue, project: project, due_date: nil) }
          let!(:due_issue3) { create(:issue, project: project, due_date: 2.days.ago) }
          let!(:due_issue4) { create(:issue, project: project, due_date: nil) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :due_date_asc)).to eq [due_issue3, due_issue1, due_issue4, due_issue2]
          end

          it 'sorts issues descending' do
            expect(resolve_issues(sort: :due_date_desc)).to eq [due_issue1, due_issue3, due_issue4, due_issue2]
          end
        end

        context 'when sorting by relative position' do
          let(:project) { create(:project) }

          let!(:relative_issue1) { create(:issue, project: project, relative_position: 2000) }
          let!(:relative_issue2) { create(:issue, project: project, relative_position: nil) }
          let!(:relative_issue3) { create(:issue, project: project, relative_position: 1000) }
          let!(:relative_issue4) { create(:issue, project: project, relative_position: nil) }

          it 'sorts issues ascending' do
            expect(resolve_issues(sort: :relative_position_asc)).to eq [relative_issue3, relative_issue1, relative_issue4, relative_issue2]
          end
        end
      end

      it 'returns issues user can see' do
        project.add_guest(current_user)

        create(:issue, confidential: true)

        expect(resolve_issues).to contain_exactly(issue1, issue2)
      end

      it 'finds a specific issue with iid' do
        expect(resolve_issues(iid: issue1.iid)).to contain_exactly(issue1)
      end

      it 'finds a specific issue with iids' do
        expect(resolve_issues(iids: issue1.iid)).to contain_exactly(issue1)
      end

      it 'finds multiple issues with iids' do
        expect(resolve_issues(iids: [issue1.iid, issue2.iid]))
          .to contain_exactly(issue1, issue2)
      end

      it 'finds only the issues within the project we are looking at' do
        another_project = create(:project)
        iids = [issue1, issue2].map(&:iid)

        iids.each do |iid|
          create(:issue, project: another_project, iid: iid)
        end

        expect(resolve_issues(iids: iids)).to contain_exactly(issue1, issue2)
      end
    end
  end

  context "when passing a non existent, batch loaded project" do
    let(:project) do
      BatchLoader::GraphQL.for("non-existent-path").batch do |_fake_paths, loader, _|
        loader.call("non-existent-path", nil)
      end
    end

    it "returns nil without breaking" do
      expect(resolve_issues(iids: ["don't", "break"])).to be_empty
    end
  end

  it 'increases field complexity based on arguments' do
    field = Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE.connection_type, resolver_class: described_class, null: false, max_page_size: 100)

    expect(field.to_graphql.complexity.call({}, {}, 1)).to eq 4
    expect(field.to_graphql.complexity.call({}, { labelName: 'foo' }, 1)).to eq 8
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
