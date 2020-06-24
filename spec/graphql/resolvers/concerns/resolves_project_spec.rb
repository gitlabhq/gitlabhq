# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResolvesProject do
  include GraphqlHelpers

  let(:implementing_class) do
    Class.new do
      include ResolvesProject
    end
  end

  subject(:instance) { implementing_class.new }

  let_it_be(:project) { create(:project) }

  it 'can resolve projects by path' do
    expect(sync(instance.resolve_project(full_path: project.full_path))).to eq(project)
  end

  it 'can resolve projects by id' do
    expect(sync(instance.resolve_project(project_id: global_id_of(project)))).to eq(project)
  end

  it 'complains when both are present' do
    expect do
      instance.resolve_project(full_path: project.full_path, project_id: global_id_of(project))
    end.to raise_error(::Gitlab::Graphql::Errors::ArgumentError)
  end

  it 'complains when neither is present' do
    expect do
      instance.resolve_project(full_path: nil, project_id: nil)
    end.to raise_error(::Gitlab::Graphql::Errors::ArgumentError)
  end
end
