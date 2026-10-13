# frozen_string_literal: true

# Helper methods for Banzai filter specs.
#
# A trimmed counterpart of the monolith's `spec/support/helpers/filter_spec_helper.rb`.
# The monolith version builds a `Banzai::RenderContext`, which is still
# ActiveRecord-coupled and lives outside this gem, so the context here is
# whatever the example passes in.
module FilterSpecHelper
  # Perform `call` on the described class.
  #
  # Returns a Nokogiri::XML::DocumentFragment
  def filter(html, context = {}, result = nil)
    described_class.call(html, context, result)
  end

  # Run text through HTML::Pipeline with the current filter and return the
  # result Hash.
  def pipeline_result(body, context = {})
    pipeline = HTML::Pipeline.new([described_class], context)
    pipeline.call(body)
  end
end
