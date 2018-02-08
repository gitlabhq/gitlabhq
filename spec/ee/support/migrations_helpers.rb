module EE
  module MigrationsHelpers
    extend ::Gitlab::Utils::Override

    override :reset_column_information
    def reset_column_information(klass)
      super
    rescue Geo::TrackingBase::SecondaryNotConfigured
    end
  end
end
