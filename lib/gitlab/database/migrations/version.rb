# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Version
        InvalidTypeError = Class.new(StandardError)

        include Comparable

        TYPE_VALUES = {
          regular: 0,
          post: 1
        }.freeze

        attr_reader :timestamp, :milestone, :type_value

        def initialize(timestamp, milestone, type)
          @timestamp = timestamp
          @milestone = Gitlab::VersionInfo.parse_from_milestone(milestone)
          self.type = type
        end

        def type
          TYPE_VALUES.key(@type_value)
        end

        def type=(value)
          @type_value = TYPE_VALUES.fetch(value.to_sym) { raise InvalidTypeError }
        end

        def milestone=(milestone_str)
          @milestone = Gitlab::VersionInfo.parse_from_milestone(milestone_str)
        end

        def regular?
          @type_value == TYPE_VALUES[:regular]
        end

        def post_deployment?
          @type_value == TYPE_VALUES[:post]
        end

        def <=>(other)
          return 0 if other.is_a?(Integer) && @timestamp == other

          return 1 unless other.is_a?(self.class)

          compare_milestones = milestone <=> other.milestone
          return compare_milestones if compare_milestones != 0

          return @type_value <=> other.type_value if @type_value != other.type_value

          @timestamp <=> other.timestamp
        end

        def to_s
          @timestamp.to_s
        end

        def to_i
          @timestamp.to_i
        end

        def coerce(_)
          [-1, timestamp.to_i]
        end

        def eql?(other)
          (self <=> other) == 0
        end

        def ==(other)
          eql?(other)
        end

        def hash
          timestamp.hash
        end
      end
    end
  end
end
