# frozen_string_literal: true

module QA
  module Runtime
    class Datastore
      # @param gdk_folder [string] path to the folder for the running GDK instance, used to determine if running locally
      def initialize(gdk_folder: nil)
        @gdk_folder = gdk_folder
      end

      # checks if a project exists in the datastore
      # @param project_name [string] name of project to be checked
      # @return [boolean]
      def has_project?(project_name)
        query_string = "select name from projects where name LIKE '#{project_name}';"

        query(query_string).include?(project_name)
      end

      def has_gdk_folder?
        !@gdk_folder.nil?
      end

      def projects
        query_string = 'select name from projects;'

        query(query_string).split("\n")
      end

      def namespaces
        query_string = 'select name from namespaces;'

        query(query_string).split("\n")
      end

      private

      # runs a query against the datastore, filters based on what the datastores it's running against
      # @param query_string [string] query to be run
      # @return [string] result of the query
      def query(query_string)
        raise 'query handler not defined for this instance' unless has_gdk_folder? # local GDK instance

        query_gdk(query_string)
      end

      # runs a query against a GDK database running locally
      # @param query_string [string] SQL query to be run
      # @return [string] result of the query
      def query_gdk(query_string)
        raise "GitLab Development Kit is not running on #{@gdk_folder}" unless gdk_is_running?

        command = "./bin/gdk psql -t -c \"#{query_string}\""

        `cd #{@gdk_folder}; #{command}`
      end

      def gdk_is_running?
        gdk_status = `cd #{@gdk_folder}; ./bin/gdk status`

        gdk_status.include?('run:') && gdk_status.exclude?('down:')
      end
    end
  end
end
