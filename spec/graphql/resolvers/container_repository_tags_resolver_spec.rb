# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ContainerRepositoryTagsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:repository) { create(:container_repository, project: project) }

  let(:args) { { sort: nil } }

  describe '#resolve' do
    let(:resolver) do
      resolve(described_class, ctx: { current_user: user }, obj: repository, args: args,
                               arg_style: :internal)
    end

    before do
      stub_container_registry_config(enabled: true)
    end

    context 'by name' do
      subject { resolver.map(&:name) }

      before do
        stub_container_registry_tags(repository: repository.path, tags: %w(aaa bab bbb ccc 123), with_manifest: false)
      end

      context 'without sort' do
        # order is not guaranteed
        it { is_expected.to contain_exactly('aaa', 'bab', 'bbb', 'ccc', '123') }
      end

      context 'with sorting and filtering' do
        context "name_asc" do
          let(:args) { { sort: :name_asc } }

          it { is_expected.to eq(%w(123 aaa bab bbb ccc)) }
        end

        context "name_desc" do
          let(:args) { { sort: :name_desc } }

          it { is_expected.to eq(%w(ccc bbb bab aaa 123)) }
        end

        context 'filter by name' do
          let(:args) { { sort: :name_desc, name: 'b' } }

          it { is_expected.to eq(%w(bbb bab)) }
        end
      end
    end
  end
end
