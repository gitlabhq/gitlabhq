# frozen_string_literal: true

require 'spec_helper'

describe Mutations::ResolvesProject do
  let(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::ResolvesProject
    end
  end

  let(:context) { double }

  subject(:mutation) { mutation_class.new(object: nil, context: context) }

  it 'uses the ProjectsResolver to resolve projects by path' do
    project = create(:project)

    expect(Resolvers::ProjectResolver).to receive(:new).with(object: nil, context: context).and_call_original
    expect(mutation.resolve_project(full_path: project.full_path).sync).to eq(project)
  end
end
