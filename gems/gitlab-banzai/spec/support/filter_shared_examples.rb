# frozen_string_literal: true

# Counterparts of the shared examples in the monolith's
# `spec/support/shared_examples/lib/banzai/filters/filter_timeout_shared_examples.rb`.
# The monolith versions drive `Gitlab::RenderTimeout`, `Gitlab::ErrorTracking`
# and project factories; these drive the gem's ports with in-memory fakes.

# Usage:
#
#   it_behaves_like 'a filter timeout' do
#     let(:text) { 'some text' }
#     let(:expected_result) { 'optional result text' }
#     let(:expected_timeout) { OVERRIDDEN_TIMEOUT_VALUE }
#   end
RSpec.shared_examples 'a filter timeout' do
  context 'when rendering takes too long' do
    let(:project) { Struct.new(:id).new(42) }
    let(:context) { { project: project } }
    let(:tracked) { [] }

    before do
      Banzai.configure do |banzai|
        banzai.with_timeout = ->(_seconds) { raise Timeout::Error }
        banzai.track_exception = ->(exception, **extra) { tracked << [exception, extra] }
      end
    end

    it 'times out' do
      result = filter(text, context)
      result = result.to_html if result.respond_to?(:to_html)

      expected = defined?(expected_result) ? expected_result : text
      expect(result).to eq expected
      expect(tracked).to contain_exactly(
        [instance_of(Timeout::Error), { project_id: 42, group_id: nil, class_name: described_class.name.demodulize }]
      )
    end

    it 'verifies render_timeout' do
      timeout = defined?(expected_timeout) ? expected_timeout : described_class::RENDER_TIMEOUT

      expect(described_class.new('Foo', project: nil).send(:render_timeout)).to eq timeout
    end
  end
end

# Usage:
#
#   it_behaves_like 'not a filter timeout' do
#     let(:text) { 'some text' }
#   end
RSpec.shared_examples 'not a filter timeout' do
  it 'does not run the filter under the time budget' do
    budgeted = 0
    Banzai.configure do |banzai|
      banzai.with_timeout = ->(_seconds, &block) do
        budgeted += 1
        block.call
      end
    end

    filter(text)

    expect(budgeted).to eq(0)
  end
end

# Usage:
#
#   it_behaves_like 'does not use pipeline timing check'
RSpec.shared_examples 'does not use pipeline timing check' do
  it 'does not include Concerns::PipelineTimingCheck' do
    expect(described_class).not_to include Banzai::Filter::Concerns::PipelineTimingCheck
  end
end

# Usage:
#
#   it_behaves_like 'pipeline timing check'
RSpec.shared_examples 'pipeline timing check' do |**opts|
  it 'checks the pipeline timing' do
    filter = described_class.new('text', defined?(context) ? context : opts.fetch(:context, {}))
    expect(filter).to receive(:exceeded_pipeline_max?).and_return(true)

    expect(filter.call).to eq(filter.doc)
  end
end

# Usage:
#
#   it_behaves_like 'limits the number of filtered items' do
#     let(:text) { 'some text' }
#     let(:ends_with) { 'result should end with this text' }
#   end
RSpec.shared_examples 'limits the number of filtered items' do |context: {}|
  before do
    stub_const('Banzai::Filter::FILTER_ITEM_LIMIT', 2)
  end

  it 'enforces limits' do
    result = if defined?(filter_result)
               filter_result
             else
               filter(text, context)
             end

    result = result.to_html unless result.is_a?(String)

    expect(result).to end_with ends_with
  end
end
