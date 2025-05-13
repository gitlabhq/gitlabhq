# frozen_string_literal: true

require "prawn"
require "prawn-svg"

module Gitlab
  module PDF
    autoload :Header, 'gitlab/pdf/header'
  end
end
