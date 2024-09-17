# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::CachingArrayResolver do
  include GraphqlHelpers

  let_it_be(:admins) { create_list(:user, 4, admin: true) }
  let(:current_user) { admins.first }
  let(:context) { { current_user: current_user } }
  let(:max_page_size) { 10 }
  let(:schema) do
    Class.new(GitlabSchema) do
      default_max_page_size 3
    end
  end

  let_it_be(:caching_resolver) do
    mod = described_class

    Class.new(::Resolvers::BaseResolver) do
      include mod
      type [::Types::UserType], null: true
      argument :is_admin, ::GraphQL::Types::Boolean, required: false

      def query_input(is_admin:)
        is_admin
      end

      def query_for(is_admin)
        if is_admin.nil?
          model_class.all
        else
          model_class.where(admin: is_admin)
        end
      end

      def model_class
        User # Happens to include FromUnion, and is cheap-ish to create
      end
    end
  end

  describe '#resolve' do
    context 'there are more than MAX_UNION_SIZE queries' do
      let_it_be(:max_union) { 3 }
      let_it_be(:resolver) do
        mod = described_class
        max = max_union

        Class.new(::Resolvers::BaseResolver) do
          include mod
          type [::Types::UserType], null: true
          argument :username, ::GraphQL::Types::String, required: false

          def query_input(username:)
            username
          end

          def query_for(username)
            if username.nil?
              model_class.all
            else
              model_class.where(username: username)
            end
          end

          def model_class
            User # Happens to include FromUnion, and is cheap-ish to create
          end

          define_method :max_union_size do
            max
          end
        end
      end

      it 'executes the queries in multiple batches' do
        users = create_list(:user, (max_union * 2) + 1)
        expect(User).to receive(:from_union).twice.and_call_original

        results = users.in_groups_of(2, false).map do |users|
          resolve(resolver, args: { username: users.map(&:username) }, schema: schema, arg_style: :internal)
        end

        expect(results.flat_map(&method(:force))).to match_array(users)
      end
    end

    context 'all queries return results' do
      let_it_be(:non_admins) { create_list(:user, 3, admin: false) }

      it 'batches the queries' do
        expect do
          [resolve_users(admin: true), resolve_users(admin: false)].each(&method(:force))
        end.to issue_same_number_of_queries_as { force(resolve_users(admin: nil)) }
      end

      it 'finds the correct values' do
        found_admins = resolve_users(admin: true)
        found_others = resolve_users(admin: false)
        admins_again = resolve_users(admin: true)
        found_all = resolve_users(admin: nil)

        expect(force(found_admins)).to match_array(admins)
        expect(force(found_others)).to match_array(non_admins)
        expect(force(admins_again)).to match_array(admins)
        expect(force(found_all)).to match_array(admins + non_admins)
      end
    end

    it 'does not perform a union of a query with itself' do
      expect(User).to receive(:where).once.and_call_original

      [resolve_users(admin: false), resolve_users(admin: false)].each(&method(:force))
    end

    context 'one of the queries returns no results' do
      it 'finds the correct values' do
        found_admins = resolve_users(admin: true)
        found_others = resolve_users(admin: false)
        found_all = resolve_users(admin: nil)

        expect(force(found_admins)).to match_array(admins)
        expect(force(found_others)).to be_empty
        expect(force(found_all)).to match_array(admins)
      end
    end

    context 'one of the queries has already been cached' do
      before do
        force(resolve_users(admin: nil))
      end

      it 'avoids further queries' do
        expect do
          repeated_find = resolve_users(admin: nil)

          expect(force(repeated_find)).to match_array(admins)
        end.not_to exceed_query_limit(0)
      end
    end

    context 'the resolver overrides item_found' do
      let_it_be(:non_admins) { create_list(:user, 2, admin: false) }
      let(:context) do
        {
          found: { true => [], false => [], nil => [] }
        }
      end

      let_it_be(:with_item_found) do
        Class.new(caching_resolver) do
          def item_found(key, item)
            context[:found][key] << item
          end
        end
      end

      it 'receives item_found for each key the item mapped to' do
        found_admins = resolve_users(admin: true, resolver: with_item_found)
        found_all = resolve_users(admin: nil, resolver: with_item_found)

        [found_admins, found_all].each(&method(:force))

        expect(context[:found]).to match({
          true => match_array(admins),
          false => be_empty,
          nil => match_array(admins + non_admins)
        })
      end
    end

    context 'the max_page_size is lower than the total result size' do
      let(:max_page_size) { 2 }

      it 'respects the max_page_size, on a per subset basis' do
        found_all = resolve_users(admin: nil)
        found_admins = resolve_users(admin: true)

        expect(force(found_all).size).to eq(2)
        expect(force(found_admins).size).to eq(2)
      end
    end

    context 'the field does not declare max_page_size' do
      let(:max_page_size) { nil }

      it 'takes the page size from schema.default_max_page_size' do
        found_all = resolve_users(admin: nil)
        found_admins = resolve_users(admin: true)

        expect(force(found_all).size).to eq(schema.default_max_page_size)
        expect(force(found_admins).size).to eq(schema.default_max_page_size)
      end
    end

    specify 'force . resolve === to_a . query_for . query_input' do
      r = resolver_instance(caching_resolver, ctx: query_context)
      args = { is_admin: false }

      naive = r.query_for(r.query_input(**args)).to_a

      expect(force(r.resolve(**args))).to eq(naive)
    end
  end

  def resolve_users(admin:, resolver: caching_resolver)
    args = { is_admin: admin }
    allow(resolver).to receive(:has_max_page_size?).and_return(true)
    allow(resolver).to receive(:max_page_size).and_return(max_page_size)
    resolve(resolver, args: args, ctx: context, schema: schema, arg_style: :internal)
  end
end
