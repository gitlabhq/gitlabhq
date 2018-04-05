module EE
  module Banzai
    module Filter
      # HTML filter that replaces epic references with links. References to
      # epics that do not exist are ignored.
      #
      # This filter supports cross-project/group references.
      module EpicReferenceFilter
        extend ActiveSupport::Concern

        module ClassMethods
          def references_in(text, pattern = object_class.reference_pattern)
            text.gsub(pattern) do |match|
              symbol = $~[object_sym]
              if object_class.reference_valid?(symbol)
                yield match, symbol.to_i, nil, $~[:group], $~
              else
                match
              end
            end
          end
        end

        def url_for_object(epic, group)
          urls = ::Gitlab::Routing.url_helpers
          urls.group_epic_url(group, epic, only_path: context[:only_path])
        end

        def data_attributes_for(text, group, object, link_content: false, link_reference: false)
          data_attribute(
            original:       text,
            link:           link_content,
            link_reference: link_reference,
            group:          group.id,
            object_sym =>   object.id
          )
        end

        def parent_records(parent, ids)
          parent.epics.where(iid: ids.to_a)
        end

        private

        def parent_type
          :group
        end
      end
    end
  end
end
