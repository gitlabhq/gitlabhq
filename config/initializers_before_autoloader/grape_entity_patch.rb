# frozen_string_literal: true

# This can be removed after the problem gets fixed on upstream.
# You can follow https://github.com/ruby-grape/grape-entity/pull/355 to see the progress.
#
# For more information about the issue;
# https://github.com/ruby/did_you_mean/issues/158#issuecomment-906056018

require 'grape-entity'

module Grape
  class Entity
    # Upstream version: https://github.com/ruby-grape/grape-entity/blob/675d3c0e20dfc1d6cf6f5ba5b46741bd404c8be7/lib/grape_entity/entity.rb#L520
    def exec_with_object(options, &block)
      if block.parameters.count == 1
        instance_exec(object, &block)
      else
        instance_exec(object, options, &block)
      end
    rescue StandardError => e
      # it handles: https://github.com/ruby/ruby/blob/v3_0_0_preview1/NEWS.md#language-changes point 3, Proc
      raise Grape::Entity::Deprecated.new e.message, 'in ruby 3.0' if e.is_a?(ArgumentError)

      raise e
    end
  end
end
