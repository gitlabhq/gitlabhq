#!/usr/bin/env ruby

# frozen_string_literal: true

require 'png_quantizator'
require 'open3'
require 'parallel'
require_relative '../tooling/lib/tooling/image'

generator = ARGV[0]
milestone = ARGV[1]

unless generator
  warn('Error: missing generator, please supply one')
  abort
end

unless milestone
  warn('Error: missing milestone, please supply one')
  abort
end

def rename_image(file, milestone)
  path = File.dirname(file)
  basename = File.basename(file, ".*")
  final_name = File.join(path, "#{basename}_v#{milestone}.png")
  FileUtils.mv(file, final_name)
end

system('spring', 'rspec', generator)

files = []

Open3.popen3("git diff --name-only -- '*.png'") do |stdin, stdout, stderr, thread|
  files.concat stdout.read.chomp.split("\n")
end

Open3.popen3("git status --porcelain -- '*.png'") do |stdin, stdout, stderr, thread|
  files.concat stdout.read.chomp.split("?? ")
end

files.reject!(&:empty?)

if files.empty?
  puts "No file generated, did you select the right screenshot generator?"
else
  puts "Compressing newly generated screenshots"

  Parallel.each(files) do |file|
    file_path = File.join(Dir.pwd, file.to_s.strip)
    was_uncompressed, savings = Tooling::Image.compress_image(file_path)
    rename_image(file_path, milestone)

    if was_uncompressed
      puts "#{file} was reduced by #{savings} bytes."
    else
      puts "Skipping already compressed file: #{file}."
    end
  end
end
