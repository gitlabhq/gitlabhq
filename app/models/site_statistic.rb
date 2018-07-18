class SiteStatistic < ActiveRecord::Base
  # prevents the creation of multiple rows
  default_value_for :id, 1

  COUNTER_ATTRIBUTES = %w(repositories_count wikis_count).freeze
  REQUIRED_SCHEMA_VERSION = 20180629153018

  def self.track(raw_attribute)
    with_statistics_available(raw_attribute) do |attribute|
      SiteStatistic.update_all(["#{attribute} = #{attribute}+1"])
    end
  end

  def self.untrack(raw_attribute)
    with_statistics_available(raw_attribute) do |attribute|
      SiteStatistic.update_all(["#{attribute} = #{attribute}-1 WHERE #{attribute} > 0"])
    end
  end

  def self.with_statistics_available(raw_attribute)
    unless raw_attribute.in?(COUNTER_ATTRIBUTES)
      raise ArgumentError, "Invalid attribute: '#{raw_attribute}' to '#{caller_locations(1, 1)[0].label}' method. " \
                           "Valid attributes are: #{COUNTER_ATTRIBUTES.join(', ')}"
    end

    return unless available?

    # we have quite a lot of specs testing migrations, we need this and the rescue to not break them
    SiteStatistic.transaction(requires_new: true) do
      SiteStatistic.first_or_create
      attribute = self.connection.quote_column_name(raw_attribute)

      yield(attribute)
    end
  end

  def self.fetch
    SiteStatistic.first_or_create!
  end

  def self.available?
    @available_flag ||= ActiveRecord::Migrator.current_version >= REQUIRED_SCHEMA_VERSION
  end

  def self.reset_column_information
    @available_flag = nil

    super
  end
end
