# frozen_string_literal: true
require 'fileutils'
require 'open3'
require 'active_support/core_ext/hash/keys'

# This module contains shared methods used by other GLFM scripts and modules.
module Glfm
  module Shared
    def write_file(file_path, file_content_string)
      FileUtils.mkdir_p(File.dirname(file_path))
      # NOTE: We don't use the block form of File.open because we want to be able to easily
      # mock it for testing.
      io = File.open(file_path, 'w')
      io.binmode
      io.write(file_content_string)
      # NOTE: We are using #fsync + #close_write instead of just #close`, in order to unit test
      # with a real StringIO and not just a mock object.
      io.fsync
      io.close_write
    end

    # All script output goes through this method. This makes it easy to mock in order to prevent
    # output from being printed to the console during tests. We don't want to directly mock
    # Kernel#puts, because that could interfere or cause spurious test failures when #puts is used
    # for debugging. And for some reason RuboCop says `rubocop:disable Rails/Output` would be
    # redundant here, so not including it.
    def output(string)
      puts string
    end

    def run_external_cmd(cmd)
      # noinspection RubyMismatchedArgumentType
      rails_root = File.expand_path('../../../', __dir__)

      # See https://stackoverflow.com/a/20001569/25192
      stdout_and_stderr_str, status = Open3.capture2e(cmd, chdir: rails_root)

      return stdout_and_stderr_str if status.success?

      warn("Error running command `#{cmd}`\n")
      warn(stdout_and_stderr_str)
      raise
    end

    # Construct an AST so we can control YAML formatting for
    # YAML block scalar literals and key quoting.
    #
    # Note that when Psych dumps the markdown to YAML, it will
    # automatically use the default "clip" behavior of the Block Chomping Indicator (`|`)
    # https://yaml.org/spec/1.2.2/#8112-block-chomping-indicator,
    # when the markdown strings contain a trailing newline. The type of
    # Block Chomping Indicator is automatically determined, you cannot specify it
    # manually.
    def dump_yaml_with_formatting(hash, literal_scalars: false)
      stringified_keys_hash = hash.deep_stringify_keys
      visitor = Psych::Visitors::YAMLTree.create
      visitor << stringified_keys_hash
      ast = visitor.tree

      # Force all scalars to have literal formatting (using Block Chomping Indicator instead of quotes)
      if literal_scalars
        ast.grep(Psych::Nodes::Scalar).each do |node|
          node.style = Psych::Nodes::Scalar::LITERAL
        end
      end

      # Do not quote the keys
      ast.grep(Psych::Nodes::Mapping).each do |node|
        node.children.each_slice(2) do |k, _|
          k.quoted = false
          k.style = Psych::Nodes::Scalar::PLAIN
        end
      end

      ast.to_yaml
    end
  end
end
