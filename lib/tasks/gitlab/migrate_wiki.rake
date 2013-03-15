namespace :gitlab do
  namespace :wiki do

    # This task will migrate all of the existing Wiki
    # content stored in your database into the new
    # Gollum Wiki system. A new repository named
    # namespace/project.wiki.git will be created for
    # each project that currently has Wiki pages in
    # the database.
    #
    # Notes:
    #  * The existing Wiki content will remain in your
    #    database in-tact.
    desc "GITLAB | Migrate Wiki content from database to Gollum repositories."
    task :migrate => :environment do
      wiki_migrator = WikiToGollumMigrator.new
      wiki_migrator.migrate!
    end
  end
end
