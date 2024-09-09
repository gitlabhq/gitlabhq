# frozen_string_literal: true

class UserMention < ApplicationRecord
  self.abstract_class = true

  include UserMentionBehaviour
end
