# frozen_string_literal: true

module QA
  module Vendor
    module Jenkins
      class Job
        include Helpers

        REQUIRED_BUILD_FIELDS = %i[name description shell_command].freeze

        # `gitlabAfter` is the commit that the push webhook announced. An empty specifier lets the
        # git plugin resolve a branch head on its own schedule, so the checkout and the
        # GitLabCommitStatusPublisher can land on different commits. A branch name such as
        # `origin/${gitlabSourceBranch}` still resolves a head at fetch time. The SHA leaves one
        # value for the whole build, so every part of it refers to the same commit.
        #
        # The plugin sets `gitlabAfter` from the webhook payload. Therefore a build that starts
        # from the Jenkins API, such as `Job#run`, has no value for it and checks out nothing.
        # A caller that needs an API-triggered build must set a different specifier.
        BRANCH_SPEC = '${gitlabAfter}'
        REFSPEC = '+refs/heads/*:refs/remotes/origin/*'

        attr_accessor(
          :name,
          :description,
          :keep_deps,
          :can_roam,
          :disabled,
          :repo_url,
          :gitlab_connection,
          :shell_command
        )

        # Prefer Jenkins::Client#jobs and Jenkins::Client.create_job over this constructor
        #
        # @param name [String] the name of the job
        # @param client [Jenkins::Client] the jenkins client
        def initialize(name, client)
          @name = name
          @client = client
        end

        # Saves the Job in Jenkins
        def create
          validate_required_fields!

          response = @client.post_xml(build, path: '/createItem', params: { name: name })

          check_network_error(response)
          response.body
        end

        # Triggers a build for the job
        def run
          @client.build(@name)
        end

        # Returns the jobs last build status
        def status
          @client.last_build_status(@name)
        end

        # Returns the jobs last log
        #
        # @param start [Integer] the log offset to query
        def log(start: 0)
          @client.last_build_log(@name, start)
        end

        # Returns whether the job is running
        #
        # @return [Boolean]
        def running?
          @client.job_running?(@name)
        end

        # Returns the count of active builds
        #
        # @return [Integer]
        def active_runs
          @client.number_of_jobs_running(@name)
        end

        # Returns the number of the build that checked out a given revision
        #
        # @param revision [String] the SHA to look for
        # @return [Integer, nil] the build number, or nil if no build used that revision
        def build_number_for_revision(revision)
          @client.build_number_for_revision(@name, revision)
        end

        # Returns whether a given build is still running
        #
        # @param build_id [Integer] the build number
        # @return [Boolean, nil] nil if the build does not exist
        def build_running?(build_id)
          @client.build_running?(@name, build_id)
        end

        # Returns the status of a given build
        #
        # @param build_id [Integer] the build number
        # @return [Symbol, nil] the build status, or nil while the build runs
        def build_status(build_id)
          @client.build_status(@name, build_id)
        end

        # Returns the log of a given build
        #
        # @param build_id [Integer] the build number
        # @param start [Integer] the log offset to query
        # @return [String] the Jenkins log/output for that build
        def build_log(build_id, start: 0)
          @client.build_log(@name, build_id, start)
        end

        private

        def validate_required_fields!
          error = REQUIRED_BUILD_FIELDS.each_with_object("") do |field, memo|
            memo << "#{field} is required\n" unless send(field)
          end
          raise ArgumentError, error unless error.empty?
        end

        def build
          builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.project do
              xml.actions
              xml.description description
              xml.keepDependencies false
              xml.properties do |props|
                build_gitlab_connection(props)
              end
              xml.canRoam true
              xml.disabled false
              xml.blockBuildWhenDownstreamBuilding false
              xml.blockBuildWhenUpstreamBuilding false
              xml.triggers do |triggers|
                build_gitlab_triggers(triggers)
              end
              # Each webhook must get its own build, and two settings are necessary for that.
              #
              # A trigger that arrives while an item waits in the queue is merged into that item,
              # and the second commit is discarded. The default quiet period keeps an item in the
              # queue for 5 seconds, so a quiet period of 0 removes that window.
              xml.quietPeriod 0
              # A trigger that arrives while a build runs is blocked until the build ends, and it
              # is then merged in the same way. Concurrent builds remove that window.
              xml.concurrentBuild true
              xml.builders do
                xml.send(:"hudson.tasks.Shell") do
                  xml.command shell_command
                  xml.configuredLocalRules
                end
              end
              xml.publishers do |publishers|
                build_gitlab_publishers(publishers)
              end
              xml.buildWrappers
              build_scm(xml)
            end
          end
          builder.to_xml
        end

        def build_scm(xml)
          if repo_url
            xml.scm(class: 'hudson.plugins.git.GitSCM') do
              xml.userRemoteConfigs do
                xml.send(:"hudson.plugins.git.UserRemoteConfig") do
                  xml.url repo_url
                  xml.name 'origin'
                  xml.refspec REFSPEC
                end
              end
              xml.branches do
                xml.send(:"hudson.plugins.git.BranchSpec") do
                  xml.name BRANCH_SPEC
                end
              end
              xml.configVersion 2
              xml.doGenerateSubmoduleConfiguration false
              xml.gitTool 'Default'
            end
          end
        end

        def build_gitlab_connection(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty") do
              xml.gitLabConnection gitlab_connection
            end
          end
        end

        def build_gitlab_triggers(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.GitLabPushTrigger") do
              xml.spec
              xml.triggerOnPush true
              # The spec pushes to the default branch and opens no merge request. An unused
              # trigger only adds another way for Jenkins to start a build.
              xml.triggerOnMergeRequest false
              xml.includeBranchesSpec 'main,master'
              xml.branchFilterType 'NameBasedFilter'
              xml.ciSkip true
            end
          end
        end

        def build_gitlab_publishers(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.publisher.GitLabCommitStatusPublisher") do
              xml.name 'jenkins'
              xml.markUnstableAsSuccess false
            end
          end
        end
      end
    end
  end
end
