# frozen_string_literal: true

# Tuple of design and version
# * has a composite ID, with lazy_find
module DesignManagement
  class DesignAtVersion
    include ActiveModel::Validations
    include GlobalID::Identification
    include Gitlab::Utils::StrongMemoize

    attr_reader :version
    attr_reader :design

    validates :version, presence: true
    validates :design, presence: true

    validate :design_and_version_belong_to_the_same_issue
    validate :design_and_version_have_issue_id

    def initialize(design: nil, version: nil)
      @design = design
      @version = version
    end

    # The ID, needed by GraphQL types and as part of the Lazy-fetch
    # protocol, includes information about both the design and the version.
    #
    # The particular format is not interesting, and should be treated as opaque
    # by all callers.
    def id
      "#{design.id}.#{version.id}"
    end

    def ==(other)
      return false unless other && self.class == other.class

      other.id == id
    end

    alias_method :eql?, :==

    def self.lazy_find(id)
      BatchLoader.for(id).batch do |ids, callback|
        find(ids).each do |record|
          callback.call(record.id, record)
        end
      end
    end

    def self.find(ids)
      pairs = ids.map { |id| id.split('.').map(&:to_i) }

      design_ids = pairs.map(&:first).uniq
      version_ids = pairs.map(&:second).uniq

      designs = ::DesignManagement::Design
        .where(id: design_ids)
        .index_by(&:id)

      versions = ::DesignManagement::Version
        .where(id: version_ids)
        .index_by(&:id)

      pairs.map do |(design_id, version_id)|
        design = designs[design_id]
        version = versions[version_id]

        obj = new(design: design, version: version)

        obj if obj.valid?
      end.compact
    end

    def status
      if not_created_yet?
        :not_created_yet
      elsif deleted?
        :deleted
      else
        :current
      end
    end

    def deleted?
      action&.deletion?
    end

    def not_created_yet?
      action.nil?
    end

    private

    def action
      strong_memoize(:most_recent_action) do
        ::DesignManagement::Action
          .most_recent.up_to_version(version)
          .find_by(design: design)
      end
    end

    def design_and_version_belong_to_the_same_issue
      id_a, id_b = [design, version].map { |obj| obj&.issue_id }

      return if id_a == id_b

      errors.add(:issue, 'must be the same on design and version')
    end

    def design_and_version_have_issue_id
      return if [design, version].all? { |obj| obj.try(:issue_id).present? }

      errors.add(:issue, 'must be present on both design and version')
    end
  end
end
