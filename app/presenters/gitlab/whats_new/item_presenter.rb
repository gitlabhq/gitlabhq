# frozen_string_literal: true

module Gitlab
  module WhatsNew
    class ItemPresenter
      DICTIONARY = {
        free: 'Free',
        starter: 'Bronze',
        premium: 'Silver',
        ultimate: 'Gold'
      }.freeze

      def self.present(item)
        if Gitlab.com?
          item['packages'] = item['packages'].map { |p| DICTIONARY[p.downcase.to_sym] }
        end

        item
      end
    end
  end
end
