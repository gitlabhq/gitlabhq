# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class IssuableLoader
        attr_reader :parent, :issuable_finder

        BatchKey = Struct.new(:parent, :finder_class, :current_user)

        def initialize(parent, issuable_finder)
          @parent = parent
          @issuable_finder = issuable_finder
        end

        def batching_find_all(&with_query)
          if issuable_finder.params.keys == ['iids']
            issuable_finder.parent = parent
            batch_load_issuables(issuable_finder.params[:iids], with_query)
          else
            post_process(find_all, with_query)
          end
        end

        def find_all
          issuable_finder.parent_param = parent if parent
          issuable_finder.execute
        end

        private

        def post_process(query, with_query)
          if with_query
            with_query.call(query)
          else
            query
          end
        end

        def batch_load_issuables(iids, with_query)
          Array.wrap(iids).map { |iid| batch_load(iid, with_query) }
        end

        def batch_load(iid, with_query)
          return if parent.nil?

          BatchLoader::GraphQL
            .for([issuable_finder.parent_param, iid.to_s])
            .batch(key: batch_key) do |params, loader, args|
              batch_key = args[:key]
              user = batch_key.current_user

              params.group_by(&:first).each do |key, group|
                iids = group.map(&:second).uniq
                args = { key => batch_key.parent, iids: iids }
                query = batch_key.finder_class.new(user, args).execute

                post_process(query, with_query).each do |item|
                  loader.call([key, item.iid.to_s], item)
                end
              end
            end
        end

        def batch_key
          BatchKey.new(parent, issuable_finder.class, issuable_finder.current_user)
        end
      end
    end
  end
end
