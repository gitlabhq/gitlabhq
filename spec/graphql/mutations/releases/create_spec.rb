# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Releases::Create do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:tag) { 'v1.1.0' }
  let(:ref) { 'master' }
  let(:name) { 'Version 1.0' }
  let(:description) { 'The first release :rocket:' }
  let(:released_at) { Time.parse('2018-12-10') }
  let(:milestones) { [milestone_12_3.title, milestone_12_4.title] }
  let(:assets) do
    {
      links: [
        {
          name: 'An asset link',
          url: 'https://gitlab.example.com/link',
          filepath: '/permanent/link',
          link_type: 'other'
        }
      ]
    }
  end

  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      tag: tag,
      ref: ref,
      name: name,
      description: description,
      released_at: released_at,
      milestones: milestones,
      assets: assets
    }
  end

  around do |example|
    freeze_time { example.run }
  end

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    let(:new_release) { subject[:release] }

    context 'when the current user has access to create releases' do
      let(:current_user) { developer }

      it 'returns no errors' do
        expect(resolve).to include(errors: [])
      end

      it 'creates the release with the correct tag' do
        expect(new_release.tag).to eq(tag)
      end

      it 'creates the release with the correct name' do
        expect(new_release.name).to eq(name)
      end

      it 'creates the release with the correct description' do
        expect(new_release.description).to eq(description)
      end

      it 'creates the release with the correct released_at' do
        expect(new_release.released_at).to eq(released_at)
      end

      it 'creates the release with the correct created_at' do
        expect(new_release.created_at).to eq(Time.current)
      end

      it 'creates the release with the correct milestone associations' do
        expected_milestone_titles = [milestone_12_3.title, milestone_12_4.title]
        actual_milestone_titles = new_release.milestones.order_by_dates_and_title.map { |m| m.title }

        expect(actual_milestone_titles).to eq(expected_milestone_titles)
      end

      describe 'asset links' do
        let(:expected_link) { assets[:links].first }
        let(:new_link) { new_release.links.first }

        it 'creates a single asset link' do
          expect(new_release.links.size).to eq(1)
        end

        it 'creates the link with the correct name' do
          expect(new_link.name).to eq(expected_link[:name])
        end

        it 'creates the link with the correct url' do
          expect(new_link.url).to eq(expected_link[:url])
        end

        it 'creates the link with the correct link type' do
          expect(new_link.link_type).to eq(expected_link[:link_type])
        end

        it 'creates the link with the correct direct filepath' do
          expect(new_link.filepath).to eq(expected_link[:filepath])
        end
      end

      context 'with protected tag' do
        context 'when user has access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

          it 'does not have errors' do
            subject

            expect(resolve).to include(errors: [])
          end
        end

        context 'when user does not have access to the protected tag' do
          let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

          it 'has an access error' do
            subject

            expect(resolve).to include(errors: ['You are not allowed to create this tag as it is protected.'])
          end
        end
      end
    end

    context "when the current user doesn't have access to create releases" do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
