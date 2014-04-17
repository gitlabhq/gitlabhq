module Gitlab
  module NoteHelper
    def self.channel(notable)
      "/notes/#{notable.class.name.underscore}/#{notable.id}"
    end
  end
end
