module Gitlab
  module CycleAnalytics
    module ClassNameUtil
      def class_name_for(type)
        class_name.split(type).first.to_sym
      end

      def class_name
        self.class.name.demodulize
      end
    end
  end
end
