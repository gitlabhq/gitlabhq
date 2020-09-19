# frozen_string_literal: true

module Gitlab
  module RobotsTxt
    def self.disallowed?(path)
      parsed_robots_txt.disallowed?(path)
    end

    def self.parsed_robots_txt
      @parsed_robots_txt ||= Parser.new(robots_txt)
    end

    def self.robots_txt
      File.read(Rails.root.join('public', 'robots.txt'))
    end
  end
end
