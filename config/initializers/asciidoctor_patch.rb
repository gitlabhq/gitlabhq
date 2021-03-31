# frozen_string_literal: true

# Ensure that locked attributes can not be changed using a counter.
# TODO: this can be removed once `asciidoctor` gem is > 2.0.12
#       and https://github.com/asciidoctor/asciidoctor/issues/3939 is merged
module Asciidoctor
  module DocumentPatch
    def counter(name, seed = nil)
      return @parent_document.counter(name, seed) if @parent_document   # rubocop: disable Gitlab/ModuleWithInstanceVariables

      unless attribute_locked? name
        super
      end
    end
  end
end

class Asciidoctor::Document
  prepend Asciidoctor::DocumentPatch
end
