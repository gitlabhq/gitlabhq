# Disable NO_ZERO_DATE mode for mysql in rails 5.
# We use zero date as a default value
# (config/initializers/active_record_mysql_timestamp.rb), in
# Rails 5 using zero date fails by default (https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/75450216)
# and NO_ZERO_DATE has to be explicitly disabled. Disabling strict mode
# is not sufficient.

require 'active_record/connection_adapters/abstract_mysql_adapter'

module MysqlZeroDate
  def configure_connection
    super

    @connection.query "SET @@SESSION.sql_mode = REPLACE(@@SESSION.sql_mode, 'NO_ZERO_DATE', '');" # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end

ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(MysqlZeroDate) if Gitlab.rails5?
