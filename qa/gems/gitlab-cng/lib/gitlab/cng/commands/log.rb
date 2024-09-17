# frozen_string_literal: true

module Gitlab
  module Cng
    module Commands
      # Logging related commands that retreive various deployment and cluster related information
      #
      class Log < Command
        desc "pods [NAME]", "Log application pods"
        long_desc <<~DESC
          Log application pods, where NAME is full or part of the pod name. Several pods can be specified, separated by a comma.
          If no NAME is specified, all pods are logged.
        DESC
        option :namespace,
          desc: "Kubernetes namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :since,
          desc: "Only return logs newer than a relative duration like 5s, 2m, or 3h. Defaults to 1h",
          type: :string,
          default: "1h"
        option :containers,
          desc: "Log all or only default containers",
          default: "all",
          type: :string,
          enum: %w[all default]
        option :save,
          desc: "Save logs to a file instead of printing to stdout",
          type: :boolean,
          default: false
        option :fail_on_missing_pods,
          desc: "Fail if no pods are found",
          type: :boolean,
          default: true
        def pods(name = "")
          logs = kubeclient.pod_logs(name.split(","), since: options[:since], containers: options[:containers])

          log(" saving logs to separate files in the current directory", :info) if options[:save]
          logs.each do |pod_name, pod_logs|
            next if pod_logs.empty?

            if options[:save]
              file_name = "#{pod_name}.log"
              File.write(file_name, pod_logs)
              next log(" created file '#{file_name}'", :success)
            end

            log("Logs for pod '#{pod_name}'", :success)
            puts pod_logs
          end
        rescue Kubectl::Client::Error => e
          raise(e) unless ["No pods matched", "No pods found in namespace"].any? { |msg| e.message.include?(msg) }

          fail_on_missing_pods = options[:fail_on_missing_pods]
          log(e.message, fail_on_missing_pods ? :error : :warn)
          exit(1) if fail_on_missing_pods
        end

        desc "events", "Log cluster events"
        long_desc <<~DESC
          Output events from the cluster for specific namespace. Useful when debugging deployment failures
        DESC
        option :namespace,
          desc: "Kubernetes namespace",
          default: "gitlab",
          type: :string,
          aliases: "-n"
        option :save,
          desc: "Save events to a file instead of printing to stdout",
          type: :boolean,
          default: false
        def events
          log("Fetching events", :info)
          events = kubeclient.events

          if options[:save]
            log(" saving events to separate file in the current directory", :info)
            file_name = "deployment-events.log"
            File.write(file_name, events)
            return log(" created file '#{file_name}'", :success)
          end

          puts events
        end

        private

        # Kubectl client
        #
        # @return [Kubectl::Client]
        def kubeclient
          @kubeclient ||= Kubectl::Client.new(options[:namespace])
        end
      end
    end
  end
end
