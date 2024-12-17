# frozen_string_literal: true

require 'rainbow'
require 'gitlab/utils/all'
require 'digest'

# rubocop:disable Rails/Output
module Gitlab
  TaskFailedError = Class.new(StandardError)
  TaskAbortedByUserError = Class.new(StandardError)

  module TaskHelpers
    include Gitlab::Utils::StrongMemoize

    extend self

    def invoke_and_time_task(task)
      start = Time.now
      Rake::Task[task].invoke
      puts "`#{task}` finished in #{Time.now - start} seconds"
    end

    # Ask if the user wants to continue
    #
    # Returns "yes" the user chose to continue
    # Raises Gitlab::TaskAbortedByUserError if the user chose *not* to continue
    def ask_to_continue
      return if Gitlab::Utils.to_boolean(ENV['GITLAB_ASSUME_YES'])

      answer = prompt(Rainbow("Do you want to continue (yes/no)? ").blue, %w[yes no])
      raise Gitlab::TaskAbortedByUserError unless answer == "yes"
    end

    # Check which OS is running
    #
    # It will primarily use lsb_relase to determine the OS.
    # It has fallbacks to Debian, SuSE, OS X and systems running systemd.
    def os_name
      os_name = run_command(%w[lsb_release -irs])
      os_name ||=
        if File.readable?('/etc/system-release')
          File.read('/etc/system-release')
        elsif File.readable?('/etc/debian_version')
          "Debian #{File.read('/etc/debian_version')}"
        elsif File.readable?('/etc/SuSE-release')
          File.read('/etc/SuSE-release')
        elsif os_x_version = run_command(%w[sw_vers -productVersion])
          "Mac OS X #{os_x_version}"
        elsif File.readable?('/etc/os-release')
          File.read('/etc/os-release').match(/PRETTY_NAME=\"(.+)\"/)[1]
        end

      os_name.try(:squish)
    end

    # Prompt the user to input something
    #
    # message - the message to display before input
    # choices - array of strings of acceptable answers or nil for any answer
    #
    # Returns the user's answer
    def prompt(message, choices = nil)
      begin
        print(message)
        answer = $stdin.gets.chomp
      end while choices.present? && choices.exclude?(answer)
      answer
    end

    # Prompt the user to input a password
    #
    # message - custom message to display before input
    def prompt_for_password(message = 'Enter password: ')
      unless $stdin.tty?
        print(message)
        return $stdin.gets.chomp
      end

      $stdin.getpass(message)
    end

    # Runs the given command and matches the output against the given pattern
    #
    # Returns nil if nothing matched
    # Returns the MatchData if the pattern matched
    #
    # see also #run_command
    # see also String#match
    def run_and_match(command, regexp)
      run_command(command).try(:match, regexp)
    end

    # Runs the given command
    #
    # Returns '' if the command was not found
    # Returns the output of the command otherwise
    #
    # see also #run_and_match
    def run_command(command)
      output, _ = Gitlab::Popen.popen(command)
      output
    rescue Errno::ENOENT
      '' # if the command does not exist, return an empty string
    end

    # Runs the given command and raises a Gitlab::TaskFailedError exception if
    # the command does not exit with 0
    #
    # Returns the output of the command otherwise
    def run_command!(command)
      output, status = Gitlab::Popen.popen(command)

      raise Gitlab::TaskFailedError, output unless status == 0

      output
    end

    def uid_for(user_name)
      run_command(%W[id -u #{user_name}]).chomp.to_i
    end

    def gid_for(group_name)
      Etc.getgrnam(group_name).gid
    rescue ArgumentError # no group
      "group #{group_name} doesn't exist"
    end

    def gitlab_user
      Gitlab.config.gitlab.user
    end

    def gitlab_user?
      strong_memoize(:is_gitlab_user) do
        current_user = run_command(%w[whoami]).chomp
        current_user == gitlab_user
      end
    end

    def warn_user_is_not_gitlab
      return if gitlab_user?

      strong_memoize(:warned_user_not_gitlab) do
        current_user = run_command(%w[whoami]).chomp

        puts Rainbow(" Warning ").color(:black).background(:yellow)
        puts "  You are running as user #{Rainbow(current_user).magenta}, we hope you know what you are doing."
        puts "  Things may work\/fail for the wrong reasons."
        puts "  For correct results you should run this as user #{Rainbow(gitlab_user).magenta}."
        puts ""
      end
    end

    def user_home
      Rails.env.test? ? Rails.root.join('tmp/tests') : Gitlab.config.gitlab.user_home
    end

    def download_package_file_version(
      version:, repo:, package_name:, package_file:, package_checksums_sha256:,
      target_path:)
      project_path = repo
        .delete_prefix('https://gitlab.com/')
        .delete_suffix('.git')

      uri = URI(
        format('https://gitlab.com/api/v4/projects/%{path}/packages/generic/%{name}/%{version}/%{file}',
          path: CGI.escape(project_path),
          name: CGI.escape(package_name),
          version: CGI.escape(version),
          file: CGI.escape(package_file)
        ))

      success = true

      Tempfile.create(package_file, binmode: true) do |file|
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new uri

          http.request(request) do |response|
            if response.code == '302'
              # Allow redirects
            elsif response.code == '200'
              response.read_body do |fragment|
                file.write(fragment)
              end
            else
              warn "HTTP Code: #{response.code} for #{uri}"
              success = false
              break
            end
          end

          file.close

          if success
            expected = package_checksums_sha256[package_file]
            actual = Digest::SHA256.file(file.path).hexdigest

            unless expected == actual
              raise <<~MESSAGE
                ERROR: Checksum mismatch for `#{package_file}`:
                  Expected: #{expected.inspect}
                    Actual: #{actual.inspect}
              MESSAGE
            end

            FileUtils.mkdir_p(File.dirname(target_path))
            FileUtils.mv(file, target_path)
          end
        end
      end

      success
    end

    def checkout_or_clone_version(version:, repo:, target_dir:, clone_opts: [])
      clone_repo(repo, target_dir, clone_opts: clone_opts) unless Dir.exist?(target_dir)
      checkout_version(get_version(version), target_dir)
    end

    # this function implements the same logic we have in omnibus for dealing with components version
    def get_version(component_version)
      # If not a valid version string following SemVer it is probably a branch name or a SHA
      # commit of one of our own component so it doesn't need `v` prepended
      return component_version unless /^\d+\.\d+\.\d+(-rc\d+)?$/.match?(component_version)

      "v#{component_version}"
    end

    def clone_repo(repo, target_dir, clone_opts: [])
      run_command!(%W[#{Gitlab.config.git.bin_path} clone] + clone_opts + %W[-- #{repo} #{target_dir}])
    end

    def checkout_version(version, target_dir)
      # Explicitly setting the git protocol version to v2 allows older Git binaries
      # to do have a shallow clone obtain objects by object ID.
      run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} config protocol.version 2])
      run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} fetch --quiet origin #{version}])
      run_command!(%W[#{Gitlab.config.git.bin_path} -C #{target_dir} checkout -f --quiet FETCH_HEAD --])
    end
  end
end
# rubocop:enable Rails/Output
