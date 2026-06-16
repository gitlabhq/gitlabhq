# frozen_string_literal: true

# Shared helpers for the bin/ scripts that generate YAML feature-metadata files
# (bin/saas-feature.rb, bin/dedicated-feature.rb).
#
# This file is intentionally pure-Ruby (no bundler / Rails dependencies) so that
# specs can use fast_spec_helper.
#
# Phase 2 (https://gitlab.com/gitlab-org/gitlab/-/issues/601414) will migrate
# bin/feature-flag to consume this module too.

require 'fileutils'
require 'httparty'
require 'json'
require 'readline'
require 'shellwords'

require_relative '../../../lib/gitlab/popen'

module FeatureGenerator
  module Shared
    Abort = Class.new(StandardError)
    Done  = Class.new(StandardError)

    WWW_GITLAB_COM_SITE        = 'https://about.gitlab.com'
    WWW_GITLAB_COM_GROUPS_JSON = "#{WWW_GITLAB_COM_SITE}/groups.json".freeze

    COPY_COMMANDS = [
      'pbcopy',                     # macOS
      'xclip -selection clipboard', # Linux
      'xsel --clipboard --input',   # Linux
      'wl-copy'                     # Wayland
    ].freeze

    OPEN_COMMANDS = [
      'open',     # macOS
      'xdg-open'  # Linux
    ].freeze

    module Helpers
      def capture_stdout(cmd)
        output = IO.popen(cmd, &:read)
        fail_with "command failed: #{cmd.join(' ')}" unless $?.success?
        output
      end

      def fail_with(message)
        raise Abort, "\e[31merror\e[0m #{message}"
      end
    end

    # Mixin for the singleton class that hosts the OptionParser logic.
    # Provides domain-neutral prompt and HTTP helpers parameterized by a
    # `noun:` keyword so each script can phrase messages using its own term
    # (for example, "SaaS feature" or "Dedicated feature").
    module OptionParserMixin
      def groups
        @groups ||= fetch_json(WWW_GITLAB_COM_GROUPS_JSON)
      end

      def group_labels
        @group_labels ||= groups.map { |_, group| group['label'] }.sort
      end

      def find_group_by_label(label)
        groups.find { |_, group| group['label'] == label }&.last
      end

      def group_list
        group_labels.map.with_index { |label, i| "#{i + 1}. #{label}" }
      end

      def fzf_available?
        find_compatible_command(%w[fzf])
      end

      # `prompt:` is part of the shared dispatch interface with prompt_fzf.
      # The readline branch ignores it because callers invoke print_prompt
      # before calling prompt_list, so the prompt is already on stdout.
      def prompt_readline(prompt:)
        Readline.readline('?> ', false)&.strip
      end

      def prompt_fzf(list:, prompt:)
        arr = list.join("\n")

        selection = IO.popen(%W[fzf --tac --prompt #{prompt}], 'r+') do |pipe|
          pipe.puts(arr)
          pipe.close_write
          pipe.readlines
        end.join.strip

        selection[/(\d+)\./, 1]
      end

      def print_list(list)
        return if list.empty?

        $stdout.puts list.join("\n")
      end

      def print_prompt(prompt)
        $stdout.puts
        $stdout.puts ">> #{prompt}:"
        $stdout.puts
      end

      def prompt_list(prompt:, list: nil)
        if fzf_available?
          prompt_fzf(list: list, prompt: prompt)
        else
          prompt_readline(prompt: prompt)
        end
      end

      def fetch_json(json_url)
        json = with_retries { HTTParty.get(json_url, format: :plain) }
        JSON.parse(json)
      end

      def with_retries(attempts: 3)
        yield
      rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, Net::OpenTimeout
        retry if (attempts -= 1).positive?

        raise
      end

      def read_group(noun:)
        prompt = "Specify the group label to which the #{noun} belongs, from the following list"

        unless fzf_available?
          print_prompt(prompt)
          print_list(group_list)
        end

        loop do
          group = prompt_list(prompt: prompt, list: group_list)
          group = group_labels[group.to_i - 1] unless group.to_i.zero?

          if group_labels.include?(group)
            $stdout.puts "You picked the group '#{group}'"
            return group
          else
            warn "The group label isn't in the above labels list"
          end
        end
      end

      def read_introduced_by_url(noun:)
        read_url(
          "URL of the MR introducing the #{noun} " \
            '(enter to skip and let Danger provide a suggestion directly in the MR):'
        )
      end

      def read_milestone
        File.read('VERSION').gsub(/^(\d+\.\d+).*$/, '\1').chomp
      end

      def read_url(prompt)
        $stdout.puts
        $stdout.puts ">> #{prompt}"

        loop do
          url = Readline.readline('?> ', false)&.strip
          url = nil if url&.empty?
          return url if url.nil? || valid_url?(url)
        end
      end

      def valid_url?(url)
        unless url.start_with?('https://')
          warn 'URL needs to start with https://'
          return false
        end

        response = HTTParty.head(url)
        return true if response.success?

        warn "URL '#{url}' isn't valid!"
        false
      end

      def open_url!(url)
        _, status = Gitlab::Popen.popen([open_command, url])
        status
      end

      def copy_to_clipboard!(text)
        IO.popen(copy_to_clipboard_command.shellsplit, 'w') { |pipe| pipe.print(text) }
      end

      def copy_to_clipboard_command
        find_compatible_command(COPY_COMMANDS)
      end

      def open_command
        find_compatible_command(OPEN_COMMANDS)
      end

      def find_compatible_command(commands)
        commands.find do |command|
          Gitlab::Popen.popen(%W[which #{command.split(' ')[0]}])[1] == 0
        end
      end
    end

    # Mixin for the Creator class. Provides file-write, amend, branch-guard,
    # and name validation. The including class must provide:
    #   - #options (with at least .name and .amend)
    #   - #file_path
    #   - #contents
    module CreatorMixin
      def write
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, contents)
      end

      def editor
        ENV['EDITOR']
      end

      def amend_commit
        fail_with 'git add failed' unless system(*%W[git add #{file_path}])

        system('git commit --amend')
      end

      def branch_name
        @branch_name ||= capture_stdout(%w[git symbolic-ref --short HEAD]).strip
      end

      def assert_feature_branch!
        return unless branch_name == 'master'

        fail_with 'Create a branch first!'
      end

      def assert_name!(noun:)
        return if options.name.match?(/\A[a-z0-9_-]+\Z/)

        fail_with "Provide a name for the #{noun} that is [a-z0-9_-]"
      end
    end
  end
end
