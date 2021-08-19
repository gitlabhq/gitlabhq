# frozen_string_literal: true
require 'date'
require 'pathname'
require "yaml"

#
# https://docs.gitlab.com/ee/development/documentation/#move-or-rename-a-page
#
namespace :gitlab do
  namespace :docs do
    desc 'GitLab | Docs | Create a doc redirect'
    task :redirect, [:old_path, :new_path] do |_, args|
      if args.old_path
        old_path = args.old_path
      else
        puts '=> Enter the path of the OLD file:'
        old_path = $stdin.gets.chomp
      end

      if args.new_path
        new_path = args.new_path
      else
        puts '=> Enter the path of the NEW file:'
        new_path = $stdin.gets.chomp
      end

      #
      # If the new path is a relative URL, find the relative path between
      # the old and new paths.
      # The returned path is one level deeper, so remove the leading '../'.
      #
      unless new_path.start_with?('http')
        old_pathname = Pathname.new(old_path)
        new_pathname = Pathname.new(new_path)
        relative_path = new_pathname.relative_path_from(old_pathname).to_s
        (_, *last) = relative_path.split('/')
        new_path = last.join('/')
      end

      #
      # - If this is an external URL, move the date 1 year later.
      # - If this is a relative URL, move the date 3 months later.
      #
      today = Time.now.utc.to_date
      date = new_path.start_with?('http') ? today >> 12 : today >> 3

      puts "=> Creating new redirect from #{old_path} to #{new_path}"
      File.open(old_path, 'w') do |post|
        post.puts '---'
        post.puts "redirect_to: '#{new_path}'"
        post.puts "remove_date: '#{date}'"
        post.puts '---'
        post.puts
        post.puts "This file was moved to [another location](#{new_path})."
        post.puts
        post.puts "<!-- This redirect file can be deleted after <#{date}>. -->"
        post.puts "<!-- Before deletion, see: https://docs.gitlab.com/ee/development/documentation/#move-or-rename-a-page -->"
      end
    end
  end
end
