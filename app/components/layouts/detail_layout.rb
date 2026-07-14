# frozen_string_literal: true

module Layouts
  class DetailLayout < Layouts::BaseLayout
    renders_one :sidebar
    renders_one :widgets
    renders_one :activity
  end
end
