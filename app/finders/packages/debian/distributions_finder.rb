# frozen_string_literal: true

module Packages
  module Debian
    class DistributionsFinder
      def initialize(container, params = {})
        @container = container
        @params = params
      end

      def execute
        collection = relation.with_container(container)
        collection = by_codename(collection)
        collection = by_suite(collection)
        by_codename_or_suite(collection)
      end

      private

      attr_reader :container, :params

      def relation
        case container
        when Project
          Packages::Debian::ProjectDistribution
        when Group
          Packages::Debian::GroupDistribution
        else
          raise ArgumentError, "Unexpected container type of '#{container.class}'"
        end
      end

      def by_codename(collection)
        return collection unless params[:codename].present?

        collection.with_codename(params[:codename])
      end

      def by_suite(collection)
        return collection unless params[:suite].present?

        collection.with_suite(params[:suite])
      end

      def by_codename_or_suite(collection)
        return collection unless params[:codename_or_suite].present?

        collection.with_codename_or_suite(params[:codename_or_suite])
      end
    end
  end
end
