module Banzai
  module Pipeline
    class AtomPipeline < FullPipeline
      def self.transform_context(context)
        super(context).merge(
          only_path: false,
          xhtml: true
        )
      end
    end
  end
end
