# frozen_string_literal: true

Time.zone = Gitlab.config.gitlab.time_zone || Time.zone
# The default is normally set by Rails in the
# active_support.initialize_time_zone Railtie, but we need to set it
# here because the config settings aren't available until after that
# runs. We set the default to ensure multi-threaded servers have the
# right value.
Time.zone_default = Time.zone
Rails.application.config.time_zone = Time.zone
