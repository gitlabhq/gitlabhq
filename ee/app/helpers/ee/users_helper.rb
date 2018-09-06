# frozen_string_literal: true

module EE
  module UsersHelper
    def users_sentence(users, link_class: nil)
      users.map { |user| link_to(user.name, user, class: link_class) }.to_sentence.html_safe
    end
  end
end
