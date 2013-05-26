require 'digest/md5'

class AddSnippetsHashkey < ActiveRecord::Migration
  def up
    add_column :snippets, :public_hashkey, :string
    Snippet.all.each { |snippet| 
      content = "#{snippet.created_at}/#{snippet.id}/#{snippet.content}"
      snippet.public_hashkey = Digest::MD5.hexdigest(content)
      snippet.save
    }
  end

  def down
    remove_column :snippets, :public_hashkey
  end
end
