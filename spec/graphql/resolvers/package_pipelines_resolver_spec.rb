# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagePipelinesResolver do
  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:package) }
  let_it_be(:pipelines) { create_list(:ci_pipeline, 3, project: package.project) }

  let(:user) { package.project.first_owner }
  let(:args) { {} }

  describe '#resolve' do
    subject { resolve(described_class, obj: package, args: args, ctx: { current_user: user }) }

    before do
      package.pipelines = pipelines
      package.save!
    end

    it { is_expected.to contain_exactly(*pipelines) }

    context 'with invalid after' do
      let(:args) { { first: 1, after: 'not_json_string' } }

      it 'raises argument error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'with invalid after key' do
      let(:args) { { first: 1, after: encode_cursor(foo: 3) } }

      it 'raises argument error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'with invalid before' do
      let(:args) { { last: 1, before: 'not_json_string' } }

      it 'raises argument error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'with invalid before key' do
      let(:args) { { last: 1, before: encode_cursor(foo: 3) } }

      it 'raises argument error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'field options' do
      let(:field) do
        field_options = described_class.field_options.merge(
          owner: resolver_parent,
          name: 'dummy_field'
        )
        ::Types::BaseField.new(**field_options)
      end

      it 'sets them properly' do
        expect(field).not_to be_connection
        expect(field.extras).to match_array([:lookahead])
      end
    end

    context 'with unauthorized user' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to be_nil }
    end

    def encode_cursor(json)
      GitlabSchema.cursor_encoder.encode(
        Gitlab::Json.dump(json),
        nonce: true
      )
    end
  end
end
