# frozen_string_literal: true

require 'tmpdir'

module TmpdirHelper
  # rubocop:disable Gitlab/ModuleWithInstanceVariables -- intentional helper mixin pattern; ivars live on the spec example instance
  def mktmpdir
    @tmpdir_helper_dirs ||= []
    @tmpdir_helper_dirs << Dir.mktmpdir
    @tmpdir_helper_dirs.last
  end

  def self.included(base)
    base.after do
      if @tmpdir_helper_dirs
        FileUtils.rm_rf(@tmpdir_helper_dirs)
        @tmpdir_helper_dirs = nil
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
