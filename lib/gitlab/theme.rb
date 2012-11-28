module Gitlab
  class Theme
    def self.css_class_by_id(id)
      themes = {
        1 => "ui-basic",
        2 => "ui-mars",
        3 => "ui-modern",
        4 => "ui-gray",
        5 => "ui-color"
      }

      id ||= 1

      return themes[id]
    end
  end
end
