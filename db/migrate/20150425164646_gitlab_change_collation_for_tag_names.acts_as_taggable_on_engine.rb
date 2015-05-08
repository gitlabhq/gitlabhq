# This migration is a duplicate of 20150425164651_change_collation_for_tag_names.acts_as_taggable_on_engine.rb
# It shold be applied before the index additions to ensure that `name` is case sensitive.

class GitlabChangeCollationForTagNames < ActiveRecord::Migration
  def up
    if ActsAsTaggableOn::Utils.using_mysql?
      execute("ALTER TABLE tags MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
    end
  end
end
