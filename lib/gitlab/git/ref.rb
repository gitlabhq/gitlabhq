# Gitaly note: JV: probably no RPC's here (just one interaction with Rugged).

module Gitlab
  module Git
    class Ref
      include Gitlab::EncodingHelper

      # Branch or tag name
      # without "refs/tags|heads" prefix
      attr_reader :name

      # Target sha.
      # Usually it is commit sha but in case
      # when tag reference on other tag it can be tag sha
      attr_reader :target

      # Dereferenced target
      # Commit object to which the Ref points to
      attr_reader :dereferenced_target

      # Extract branch name from full ref path
      #
      # Ex.
      #   Ref.extract_branch_name('refs/heads/master') #=> 'master'
      def self.extract_branch_name(str)
        str.gsub(%r{\Arefs/heads/}, '')
      end

      # Gitaly: this method will probably be migrated indirectly via its call sites.
      def self.dereference_object(object)
        object = object.target while object.is_a?(Rugged::Tag::Annotation)

        object
      end

      def initialize(repository, name, target, dereferenced_target)
        @name = Gitlab::Git.ref_name(name)
        @dereferenced_target = dereferenced_target
        @target = if target.respond_to?(:oid)
                    target.oid
                  elsif target.respond_to?(:name)
                    target.name
                  elsif target.is_a? String
                    target
                  else
                    nil
                  end
      end
    end
  end
end
