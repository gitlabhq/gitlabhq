# frozen_string_literal: true

require 'spec_helper'

describe Mutations::ResolvesIssuable do
  let(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::ResolvesIssuable
    end
  end

  let(:project)  { create(:project) }
  let(:user)     { create(:user) }
  let(:context)  { { current_user: user } }
  let(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }

  shared_examples 'resolving an issuable' do |type|
    context 'when user has access' do
      let(:source) { type == :merge_request ? 'source_project' : 'project' }
      let(:issuable) { create(type, author: user, "#{source}" => project) }

      subject { mutation.resolve_issuable(type: type, parent_path: project.full_path, iid: issuable.iid) }

      before do
        project.add_developer(user)
      end

      it 'resolves issuable by iid' do
        result = type == :merge_request ? subject.sync : subject
        expect(result).to eq(issuable)
      end

      it 'uses the correct Resolver to resolve issuable' do
        resolver_class = "Resolvers::#{type.to_s.classify.pluralize}Resolver".constantize
        resolved_project = mutation.resolve_project(full_path: project.full_path)

        allow(mutation).to receive(:resolve_project)
          .with(full_path: project.full_path)
          .and_return(resolved_project)

        expect(resolver_class).to receive(:new)
          .with(object: resolved_project, context: context, field: nil)
          .and_call_original

        subject
      end

      it 'uses the ResolvesProject to resolve project' do
        expect(Resolvers::ProjectResolver).to receive(:new)
          .with(object: nil, context: context, field: nil)
          .and_call_original

        subject
      end

      it 'returns nil if issuable is not found' do
        result = mutation.resolve_issuable(type: type, parent_path: project.full_path, iid: "100")
        result = type == :merge_request ? result.sync : result

        expect(result).to be_nil
      end
    end
  end

  context 'with issues' do
    it_behaves_like 'resolving an issuable', :issue
  end

  context 'with merge requests' do
    it_behaves_like 'resolving an issuable', :merge_request
  end
end
