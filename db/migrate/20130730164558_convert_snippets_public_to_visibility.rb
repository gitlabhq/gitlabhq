class ConvertSnippetsPublicToVisibility < ActiveRecord::Migration
  def up
    Snippet.transaction do
      Snippet.where(private: true).update_all(visibility: :private)
      Snippet.where(private: false).update_all(visibility: :gitlab_public)
    end
  end

  def down
    Snippet.transaction do
      Snippet.where(visibility: :private).update_all(private: true)
      Snippet.where(visibility: :gitlab_public).update_all(private: false)
    end
  end
end
