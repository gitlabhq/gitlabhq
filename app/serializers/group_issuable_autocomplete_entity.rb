# frozen_string_literal: true

class GroupIssuableAutocompleteEntity < Grape::Entity
  expose :iid
  expose :title
  expose :reference do |issuable, options|
    issuable.to_reference(options[:parent_group])
  end
  expose :icon_name, safe: true
end
