# frozen_string_literal: true

module Autocomplete
  class IssuableEntity < Grape::Entity
    expose :iid
    expose :title
    expose :reference do |issuable, options|
      issuable.to_reference(options[:parent])
    end
    expose :icon_name, safe: true
  end
end
