# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseObject, feature_category: :api do
  include GraphqlHelpers
  include_context 'with test GraphQL schema'

  let(:skip_auth_schema) do
    comment_type = Class.new(described_class) do
      graphql_name 'Comment'
      authorize :read_post

      field :comment, String
    end

    post_type = Class.new(described_class) do
      graphql_name 'Post'
      authorize :read_post

      field :title, String
      field :comments, [comment_type]
    end

    blog_type = Class.new(described_class) do
      graphql_name 'Blog'

      field :skip_auth_posts, [post_type], null: true, skip_type_authorization: :read_post
      field :with_auth_posts, [post_type], null: true

      field :skip_auth_posts_collection, post_type.connection_type, null: true, skip_type_authorization: :read_post
      field :with_auth_posts_collection, post_type.connection_type, null: true,
        connection_extension: Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

      field :skip_auth_last_post, post_type, null: true, skip_type_authorization: :read_post
      field :with_auth_last_post, post_type, null: true

      # make this act as a resolver
      def skip_auth_posts
        object[:skip_auth_posts].keep_if do |post|
          Ability.allowed?(context[:current_user], :read_post, post)
        end
      end

      # make this act as a resolver
      def skip_auth_posts_collection
        ::Gitlab::Graphql::Lazy.new do
          object[:skip_auth_posts_collection].keep_if do |post|
            Ability.allowed?(context[:current_user], :read_post, post)
          end
        end
      end

      # make this act as a resolver
      def with_auth_posts_collection
        ::Gitlab::Graphql::Lazy.new do
          Gitlab::Graphql::ExternallyPaginatedArray.new(nil, nil, *object[:with_auth_posts_collection])
        end
      end

      def skip_auth_last_post
        can_read = Ability.allowed?(context[:current_user], :read_post, object[:skip_auth_last_post])
        object[:skip_auth_last_post] if can_read
      end

      def with_auth_last_post
        can_read = Ability.allowed?(context[:current_user], :read_post, object[:with_auth_last_post])
        object[:with_auth_last_post] if can_read
      end
    end

    Class.new(test_schema) do
      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'
        field :blog, blog_type, null: true

        def blog
          ::Gitlab::Graphql::Lazy.new { context[:blog] }
        end
      end)

      def unauthorized_object(_err)
        nil
      end
    end
  end

  describe 'authorization options' do
    let(:posts) do
      [
        { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] },
        { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] },
        { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
      ]
    end

    let(:data) do
      {
        scope_validator: scope_validator,
        current_user: :the_user,
        blog: {
          with_auth_posts: posts,
          skip_auth_posts: posts,
          skip_auth_posts_collection: posts,
          with_auth_posts_collection: posts,
          skip_auth_last_post: posts.last,
          with_auth_last_post: posts.last
        }
      }
    end

    context 'when skipping type authorization on resolved value' do
      context 'with array type collection' do
        it 'returns collection of allowed values' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                skipAuthPosts {
                  title
                  comments {
                    comment
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 3 times, explicitly called in the skip_auth_posts method resolver
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] }
          ).and_return(true)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] }
          ).and_return(false)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              'skipAuthPosts',
              [
                { 'title' => "First", "comments" => [{ "comment" => 'hi' }, { "comment" => 'bye' }] },
                { 'title' => "Third", "comments" => [{ "comment" => 'awesome' }, { "comment" => 'nice' }] }
              ]
            ]
          )
        end
      end

      context 'with connection type collection' do
        it 'returns collection of allowed values' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                skipAuthPostsCollection {
                  nodes {
                    title
                    comments {
                      comment
                    }
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 3 times, explicitly called in the skip_auth_posts_collection method resolver
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] }
          ).and_return(true)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] }
          ).and_return(false)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              "skipAuthPostsCollection",
              {
                "nodes" =>
                  [
                    { "title" => "First", "comments" => [{ "comment" => "hi" }, { "comment" => "bye" }] },
                    { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
                  ]
              }
            ]
          )
        end
      end

      context 'with single value type' do
        it 'returns the value' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                skipAuthLastPost {
                  title
                  comments {
                    comment
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 1 time, explicitly called in the skip_auth_last_post method resolver, but it skips
          # ability check in BaseObject#authorized?
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              "skipAuthLastPost",
              { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
            ]
          )
        end
      end
    end

    context 'when not skipping type authorization on resolved value' do
      context 'with array type collection' do
        it 'returns collection of allowed values' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                withAuthPosts {
                  title
                  comments {
                    comment
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 13 times
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] }
          ).and_return(true)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] }
          ).and_return(false)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)

          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'hi' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'bye' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'awesome' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'nice' }).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              'withAuthPosts',
              [
                { 'title' => "First", "comments" => [{ "comment" => 'hi' }, { "comment" => 'bye' }] },
                { 'title' => "Third", "comments" => [{ "comment" => 'awesome' }, { "comment" => 'nice' }] }
              ]
            ]
          )
        end
      end

      context 'with connection type collection' do
        it 'returns collection of allowed values' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                withAuthPostsCollection {
                  nodes {
                    title
                    comments {
                      comment
                    }
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 13 times
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] }
          ).and_return(true)
          expect(Ability).to receive(:allowed?).once.with(
            :the_user, :read_post, { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] }
          ).and_return(false)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)

          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'hi' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'bye' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'awesome' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'nice' }).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              "withAuthPostsCollection",
              {
                "nodes" =>
                  [
                    { "title" => "First", "comments" => [{ "comment" => "hi" }, { "comment" => "bye" }] },
                    { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
                  ]
              }
            ]
          )
        end
      end

      context 'with single value type' do
        it 'returns allowed values' do
          doc = GraphQL.parse(<<~GQL)
            query {
              blog {
                withAuthLastPost {
                  title
                  comments {
                    comment
                  }
                }
              }
            }
          GQL

          # calls Ability.allowed? - 2 times, explicitly called in the with_auth_last_post method resolver, and also
          # called by BaseObject#authorized?
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
          ).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'awesome' }).and_return(true)
          expect(Ability).to receive(:allowed?).twice.with(
            :the_user, :read_post, { comment: 'nice' }).and_return(true)

          query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
          result = query.result.to_h
          things = result.dig('data', 'blog')

          expect(things).to contain_exactly(
            [
              "withAuthLastPost",
              { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
            ]
          )
        end
      end
    end

    context 'when fields of same type are defined with skip and not skip type auth' do
      it 'returns all values' do
        doc = GraphQL.parse(<<~GQL)
          query {
            blog {
              skipAuthPosts {
                title
                comments {
                  comment
                }
              }
              withAuthPosts {
                title
                comments {
                  comment
                }
              }
              skipAuthPostsCollection {
                nodes {
                  title
                  comments {
                    comment
                  }
                }
              }
              withAuthPostsCollection {
                nodes {
                  title
                  comments {
                    comment
                  }
                }
              }
              skipAuthLastPost {
                title
                comments {
                  comment
                }
              }
              withAuthLastPost {
                title
                comments {
                  comment
                }
              }
            }
          }
        GQL

        expect(Ability).to receive(:allowed?).exactly(6).times.with(
          :the_user, :read_post, { title: 'First', comments: [{ comment: 'hi' }, { comment: 'bye' }] }
        ).and_return(true)
        expect(Ability).to receive(:allowed?).once.with(
          :the_user, :read_post, { title: 'Second', comments: [{ comment: 'bad' }, { comment: 'good' }] }
        ).and_return(false)
        expect(Ability).to receive(:allowed?).exactly(9).times.with(
          :the_user, :read_post, { title: 'Third', comments: [{ comment: 'awesome' }, { comment: 'nice' }] }
        ).and_return(true)

        expect(Ability).to receive(:allowed?).exactly(4).times.with(
          :the_user, :read_post, { comment: 'hi' }).and_return(true)
        expect(Ability).to receive(:allowed?).exactly(4).times.with(
          :the_user, :read_post, { comment: 'bye' }).and_return(true)
        expect(Ability).to receive(:allowed?).exactly(6).times.with(
          :the_user, :read_post, { comment: 'awesome' }).and_return(true)
        expect(Ability).to receive(:allowed?).exactly(6).times.with(
          :the_user, :read_post, { comment: 'nice' }).and_return(true)

        query = GraphQL::Query.new(skip_auth_schema, document: doc, context: data)
        result = query.result.to_h
        things = result.dig('data', 'blog')

        expect(things).to contain_exactly(
          [
            'skipAuthPosts',
            [
              { 'title' => "First", "comments" => [{ "comment" => 'hi' }, { "comment" => 'bye' }] },
              { 'title' => "Third", "comments" => [{ "comment" => 'awesome' }, { "comment" => 'nice' }] }
            ]
          ],
          [
            'withAuthPosts',
            [
              { 'title' => "First", "comments" => [{ "comment" => 'hi' }, { "comment" => 'bye' }] },
              { 'title' => "Third", "comments" => [{ "comment" => 'awesome' }, { "comment" => 'nice' }] }
            ]
          ],
          [
            "skipAuthPostsCollection",
            {
              "nodes" =>
                [
                  { "title" => "First", "comments" => [{ "comment" => "hi" }, { "comment" => "bye" }] },
                  { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
                ]
            }
          ],
          [
            "withAuthPostsCollection",
            {
              "nodes" =>
                [
                  { "title" => "First", "comments" => [{ "comment" => "hi" }, { "comment" => "bye" }] },
                  { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
                ]
            }
          ],
          [
            "skipAuthLastPost",
            { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
          ],
          [
            "withAuthLastPost",
            { "title" => "Third", "comments" => [{ "comment" => "awesome" }, { "comment" => "nice" }] }
          ]
        )
      end
    end
  end
end
