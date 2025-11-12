# frozen_string_literal: true

class SecApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :sec, reading: :sec } if Gitlab::Database.has_config?(:sec)

  UnflaggedVulnReadDatabaseTriggerTransaction = Class.new(StandardError)

  class << self
    def backup_model
      Vulnerabilities::Backup.descendants.find { |descendant| self == descendant.original_model }
    end

    ####################
    # This transaction code exists to help identify and prevent instances of code that may need to explicitly pass
    # a feature flag setting to the vulnerability reads database trigger.
    #
    # Once transitioned away from the database trigger, we can remove it.
    def feature_flagged_transaction_for(projects)
      SecApplicationRecord.transaction do
        ::SecApplicationRecord.pass_feature_flag_to_vuln_reads_db_trigger(projects)

        yield
      end
    end

    def db_trigger_flag_not_set?
      result = ::SecApplicationRecord.connection.execute(
        "SELECT current_setting('vulnerability_management.dont_execute_db_trigger', true);"
      ).first['current_setting']

      result ? result.empty? : result.nil?
    end

    def pass_feature_flag_to_vuln_reads_db_trigger(projects)
      unless ::SecApplicationRecord.connection.transaction_open?
        raise StandardError, 'pass_feature_flag_to_vuln_reads_db_trigger must be called within a transaction'
      end

      feature_enabled = if projects.nil?
                          Feature.enabled?(:turn_off_vulnerability_read_create_db_trigger_function, :instance)
                        else
                          Array(projects).all? do |project|
                            Feature.enabled?(
                              :turn_off_vulnerability_read_create_db_trigger_function, project)
                          end
                        end

      ::SecApplicationRecord.connection.execute("SELECT set_config(
      'vulnerability_management.dont_execute_db_trigger', '#{feature_enabled}', true);")
    end
    ##################
  end
end
