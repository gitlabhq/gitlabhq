class MoveNoteFolder < ActiveRecord::Migration
  def up
    system(
      "if [ -d '#{Rails.root}/public/uploads/note' ];
        then mv #{Rails.root}/public/uploads/note #{Rails.root}/uploads/note;
        echo 'note folder has been moved successfully';
      else
        echo 'note folder has already been moved or does not exist yet. Nothing to do here.'; fi")
  end

  def down
    system(
      "if [ -d '#{Rails.root}/uploads/note' ];
        then mv #{Rails.root}/uploads/note #{Rails.root}/public/uploads/note;
        echo 'note folder has been moved successfully';
      else
        echo 'note folder has already been moved or does not exist yet. Nothing to do here.'; fi")
  end
end
