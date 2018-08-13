# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_mysql_adapter'

module MysqlSessionOptions
  def configure_connection
    super

    # Disable NO_ZERO_DATE mode for mysql.
    # We use zero date as a default value
    # (config/initializers/active_record_mysql_timestamp.rb), in
    # Rails 5 using zero date fails by default (https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/75450216)
    # and NO_ZERO_DATE has to be explicitly disabled. Disabling strict mode
    # is not sufficient.
    sql_mode = "REPLACE(@@sql_mode, 'NO_ZERO_DATE', '')"

    # Disable ONLY_FULL_GROUP_BY for mysql.
    # If ONLY_FULL_GROUP_BY is enabled then GROUP BY clause
    # must include all columns used in SELECT, HAVING and ORDER BY.
    # This causes that "duplicit" records are then returned in
    # some of our queries and these have to be filtered-out
    # on rails side.
    sql_mode = "REPLACE(#{sql_mode}, 'ONLY_FULL_GROUP_BY', '')"

    @connection.query "SET @@SESSION.sql_mode = #{sql_mode};" # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end

ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(MysqlSessionOptions) if Gitlab.rails5?
