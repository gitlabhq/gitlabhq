# frozen_string_literal: true

module Gitlab
  module GithubImport
    # ObjectImporter defines the base behaviour for every Sidekiq worker that
    # imports a single resource such as a note or pull request.
    module ObjectImporter
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker
        include GithubImport::Queue
        include ReschedulingMethods
        include NotifyUponDeath
      end

      # project - An instance of `Project` to import the data into.
      # client - An instance of `Gitlab::GithubImport::Client`
      # hash - A Hash containing the details of the object to import.
      def import(project, client, hash)
        object = representation_class.from_json_hash(hash)

        importer_class.new(object, project, client).execute

        counter.increment(project: project.full_path)
      end

      def counter
        @counter ||= Gitlab::Metrics.counter(counter_name, counter_description)
      end

      # Returns the representation class to use for the object. This class must
      # define the class method `from_json_hash`.
      def representation_class
        raise NotImplementedError
      end

      # Returns the class to use for importing the object.
      def importer_class
        raise NotImplementedError
      end

      # Returns the name (as a Symbol) of the Prometheus counter.
      def counter_name
        raise NotImplementedError
      end

      # Returns the description (as a String) of the Prometheus counter.
      def counter_description
        raise NotImplementedError
      end
    end
  end
end
