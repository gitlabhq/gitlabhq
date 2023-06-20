# frozen_string_literal: true

require 'declarative_policy'

# This module speeds up class resolution by caching it.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119924
# See https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/issues/30
module ClassForClassCache
  def self.prepended(base)
    class << base
      attr_accessor :class_for_class_cache
    end

    base.class_for_class_cache = {}
    base.singleton_class.prepend(SingletonClassMethods)
  end

  module SingletonClassMethods
    def class_for_class(subject_class)
      class_for_class_cache.fetch(subject_class) do
        class_for_class_cache[subject_class] = super
      end
    end
  end
end

DeclarativePolicy.configure do
  named_policy :global, ::GlobalPolicy
end

DeclarativePolicy.prepend(ClassForClassCache)
