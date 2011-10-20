require 'grit'
require 'albino'
require "utils"

Grit::Blob.class_eval do
  include Utils::FileHelper
  include Utils::Colorize
end
