require 'securerandom'

module QA
  module Scenario
    module Gitlab
      module Repository
        class Push < Scenario::Template
          attr_writer :description

          def initialize
            @files = {}
            @commit = "Commiting files"
          end

          def add_file(name, contents)
            @files[name] = contents
          end

          def commit=(raw_commit)
            @raw_commit = raw_commit
          end

          def perform
            Git::Repository.perform do |repository|
              repository.location = Page::Project::Show.act do
                choose_repository_clone_http
                repository_location
              end

              repository.use_default_credentials

              repository.act do
                clone
                configure_identity('GitLab QA', 'root@gitlab.com')
                @files.each { |file, content| add_file(file, content) }
                commit(commit_title)
                push_changes
                @last_commit = last_commit_sha
              end
            end

            self
          end

          def commit_title
            "#{@raw_commit} - #{stamp}"
          end

          def last_commit(size: :long)
            size == :short ? @last_commit[0...8] : @last_commit
          end

          private

          def stamp
            @stamp ||= SecureRandom.hex(8)
          end
        end
      end
    end
  end
end
