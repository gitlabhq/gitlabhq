require 'spec_helper'

describe PathLocksHelper do
  describe '#text_label_for_lock' do
    it "return correct string for non-nested locks" do
      user = create :user, name: 'John'
      path_lock = create :path_lock, path: 'app', user: user
      expect(text_label_for_lock(path_lock, 'app')).to eq('Locked by John')
    end

    it "return correct string for nested locks" do
      user = create :user, name: 'John'
      path_lock = create :path_lock, path: 'app', user: user
      expect(text_label_for_lock(path_lock, 'app/models')).to eq('John has a lock on "app"')
    end
  end
end
