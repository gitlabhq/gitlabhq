require 'fogbugz'

module Gitlab
  module FogbugzImport
    class Client
      attr_reader :api

      def initialize(options = {})
        if options[:uri] && options[:token]
          @api = ::Fogbugz::Interface.new(options)
        elsif options[:uri] && options[:email] && options[:password]
          @api = ::Fogbugz::Interface.new(options)
          @api.authenticate
          @api
        end
      end

      def get_token
        @api.token
      end

      def valid?
        !get_token.blank?
      end

      def user_map
        users = {}
        res = @api.command(:listPeople)
        [res['people']['person']].flatten.each do |user|
          users[user['ixPerson']] = { name: user['sFullName'], email: user['sEmail'] }
        end
        users
      end

      def repos
        res = @api.command(:listProjects)
        @repos ||= res['projects']['project'].map { |proj| FogbugzImport::Repository.new(proj) }
      end

      def repo(id)
        repos.find { |r| r.id.to_s == id.to_s }
      end

      def cases(project_id)
        project_name = repo(project_id).name
        res = @api.command(:search, q: "project:'#{project_name}'", cols: 'ixPersonAssignedTo,ixPersonOpenedBy,ixPersonClosedBy,sStatus,sPriority,sCategory,fOpen,sTitle,sLatestTextSummary,dtOpened,dtClosed,dtResolved,dtLastUpdated,events')
        return [] unless res['cases']['count'].to_i > 0

        res['cases']['case']
      end

      def categories
        @api.command(:listCategories)
      end
    end
  end
end
