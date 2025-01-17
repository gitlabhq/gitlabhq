#!/usr/bin/env ruby

# frozen_string_literal: true

require 'json'
require 'pathname'

class MinifySimplecovResultsets
  ROOT_DIR = Pathname.new(__dir__).parent

  def minify
    resultsets = Dir.glob(ROOT_DIR.join('coverage', '*', '.resultset.json'))
    resultsets.each do |path|
      path = Pathname.new(path)
      content = File.read(path)
      size_before = content.length
      content = JSON.dump(JSON.parse(content))
      size_after = content.length
      File.write(path, content)

      delta = "(#{(100 * (size_after - size_before) / size_before).round}%)"
      size_before = "#{(size_before / 1024).round}KB"
      size_after = "#{(size_after / 1024).round}KB"
      puts "Minified #{path.relative_path_from(ROOT_DIR)}: #{size_before} -> #{size_after} #{delta}"
    end
  end
end

MinifySimplecovResultsets.new.minify if $PROGRAM_NAME == __FILE__
