# frozen_string_literal: true

class PersonalSnippet < Snippet
  include WithUploads
end

PersonalSnippet.prepend(EE::PersonalSnippet)
