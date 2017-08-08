module Gitlab
  module Git
    module Local
      module Ref
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          def dereference_object(object)
            object = object.target while object.is_a?(Rugged::Tag::Annotation)
    
            object
          end
        end
      end
    end
  end
end
