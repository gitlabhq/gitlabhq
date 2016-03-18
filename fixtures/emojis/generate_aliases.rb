#!/usr/bin/env ruby

require 'json'

aliases = {}

index_file = File.expand_path("./index.json")
index = JSON.parse(File.read(index_file))

index.each_pair do |key, data|
  data['aliases'].each do |a|
    a.tr!(':', '')

    aliases[a] = key
  end
end

puts JSON.pretty_generate(aliases, indent: '   ', space: '', space_before: '')
