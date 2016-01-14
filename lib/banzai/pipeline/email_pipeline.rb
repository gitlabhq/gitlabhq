module Banzai
  module Pipeline
    class EmailPipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge(
          only_path: false
        )
      end
    end
  end
end
