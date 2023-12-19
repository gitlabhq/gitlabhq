# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::JobBaseField, feature_category: :fleet_visibility do
  describe 'authorized?' do
    let_it_be(:current_user) { create(:user) }

    let(:object) { double }
    let(:ctx) { { current_user: current_user, current_field: current_field } }
    let(:current_field) { instance_double(described_class, original_name: current_field_name.to_sym) }
    let(:args) { {} }

    subject(:field) do
      described_class.new(name: current_field_name, type: GraphQL::Types::String, null: true, **args)
    end

    context 'when :job_field_authorization is specified' do
      let(:ctx) { { current_user: current_user, current_field: current_field, job_field_authorization: :foo } }

      context 'with public field' do
        using RSpec::Parameterized::TableSyntax

        where(:current_field_name) do
          %i[allow_failure duration id kind status created_at finished_at queued_at queued_duration updated_at runner]
        end

        with_them do
          it 'returns true without authorizing' do
            is_expected.to be_authorized(object, nil, ctx)
          end
        end
      end

      context 'with private field' do
        let(:current_field_name) { 'short_sha' }

        context 'when permission is not allowed' do
          it 'returns false' do
            expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(false)

            is_expected.not_to be_authorized(object, nil, ctx)
          end
        end

        context 'when permission is allowed' do
          it 'returns true' do
            expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(true)

            is_expected.to be_authorized(object, nil, ctx)
          end
        end
      end
    end

    context 'when :job_field_authorization is not specified' do
      let(:current_field_name) { 'status' }

      it 'defaults to true' do
        is_expected.to be_authorized(object, nil, ctx)
      end

      context 'when field is authorized' do
        let(:args) { { authorize: :foo } }

        it 'tests the field authorization' do
          expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(false)

          expect(field).not_to be_authorized(object, nil, ctx)
        end

        it 'tests the field authorization, if provided, when it succeeds' do
          expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(true)

          expect(field).to be_authorized(object, nil, ctx)
        end
      end

      context 'with field resolver' do
        let(:resolver) { Class.new(Resolvers::BaseResolver) }
        let(:args) { { resolver_class: resolver } }

        it 'only tests the resolver authorization if it authorizes_object?' do
          is_expected.to be_authorized(object, nil, ctx)
        end

        context 'when resolver authorizes object' do
          let(:resolver) do
            Class.new(Resolvers::BaseResolver) do
              include Gitlab::Graphql::Authorize::AuthorizeResource

              authorizes_object!
            end
          end

          it 'tests the resolver authorization, if provided' do
            expect(resolver).to receive(:authorized?).with(object, ctx).and_return(false)

            expect(field).not_to be_authorized(object, nil, ctx)
          end

          context 'when field is authorized' do
            let(:args) { { authorize: :foo, resolver_class: resolver } }

            it 'tests field authorization before resolver authorization, when field auth fails' do
              expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(false)
              expect(resolver).not_to receive(:authorized?)

              expect(field).not_to be_authorized(object, nil, ctx)
            end

            it 'tests field authorization before resolver authorization, when field auth succeeds' do
              expect(Ability).to receive(:allowed?).with(current_user, :foo, object).and_return(true)
              expect(resolver).to receive(:authorized?).with(object, ctx).and_return(false)

              expect(field).not_to be_authorized(object, nil, ctx)
            end
          end
        end
      end
    end
  end

  describe '#resolve' do
    context 'when late_extensions is given' do
      it 'registers the late extensions after the regular extensions' do
        extension_class = Class.new(GraphQL::Schema::Field::ConnectionExtension)
        field = described_class.new(name: 'private_field', type: GraphQL::Types::String.connection_type,
          null: true, late_extensions: [extension_class])

        expect(field.extensions.last.class).to be(extension_class)
      end
    end
  end

  include_examples 'Gitlab-style deprecations' do
    def subject(args = {})
      base_args = { name: 'private_field', type: GraphQL::Types::String, null: true }

      described_class.new(**base_args.merge(args))
    end
  end
end
