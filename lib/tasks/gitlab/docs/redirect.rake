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

    desc 'GitLab | Docs | Clean up old redirects'
    task :clean_redirects do
      #
      # Calculate new path from the redirect URL.
      #
      # If the redirect is not a full URL:
      #   1. Create a new Pathname of the file
      #   2. Use dirname to get all but the last component of the path
      #   3. Join with the redirect_to entry
      #   4. Substitute:
      #      - '.md' => '.html'
      #      - 'doc/' => '/ee/'
      #
      # If the redirect URL is a full URL pointing to the Docs site
      # (cross-linking among the 4 products), remove the FQDN prefix:
      #
      #   From : https://docs.gitlab.com/ee/install/requirements.html
      #   To   : /ee/install/requirements.html
      #
      def new_path(redirect, filename)
        if !redirect.start_with?('http')
          Pathname.new(filename).dirname.join(redirect).to_s.gsub(%r(\.md), '.html').gsub(%r(doc/), '/ee/')
        elsif redirect.start_with?('https://docs.gitlab.com')
          redirect.gsub('https://docs.gitlab.com', '')
        else
          redirect
        end
      end

      today = Time.now.utc.to_date

      #
      # Find the files to be deleted.
      # Exclude 'doc/development/documentation/index.md' because it
      # contains an example of the YAML front matter.
      #
      files_to_be_deleted = `grep -Ir 'remove_date:' doc | grep -v doc/development/documentation/index.md | cut -d ":" -f 1`.split("\n")

      #
      # Iterate over the files to be deleted and print the needed
      # YAML entries for the Docs site redirects.
      #
      files_to_be_deleted.each do |filename|
        frontmatter = YAML.safe_load(File.read(filename))
        remove_date = Date.parse(frontmatter['remove_date'])
        old_path = filename.gsub(%r(\.md), '.html').gsub(%r(doc/), '/ee/')

        #
        # Check if the removal date is before today, and delete the file and
        # print the content to be pasted in
        # https://gitlab.com/gitlab-org/gitlab-docs/-/blob/master/content/_data/redirects.yaml.
        # The remove_date of redirects.yaml should be nine months in the future.
        # To not be confused with the remove_date of the Markdown page.
        #
        next unless remove_date < today

        File.delete(filename) if File.exist?(filename)
        puts "  - from: #{old_path}"
        puts "    to: #{new_path(frontmatter['redirect_to'], filename)}"
        puts "    remove_date: #{remove_date >> 9}"
      end
    end
  end
end
