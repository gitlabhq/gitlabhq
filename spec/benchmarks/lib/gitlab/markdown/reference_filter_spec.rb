require 'spec_helper'

describe Gitlab::Markdown::ReferenceFilter, benchmark: true do
  let(:input) do
    html = <<-EOF
<p>Hello @alice and @bob, how are you doing today?</p>
<p>This is simple @dummy text to see how the @ReferenceFilter class performs
when @processing HTML.</p>
    EOF

    Nokogiri::HTML.fragment(html)
  end

  let(:project) { create(:empty_project) }

  let(:filter) { described_class.new(input, project: project) }

  describe '#replace_text_nodes_matching' do
    let(:iterations) { 6000 }

    describe 'with identical input and output HTML' do
      benchmark_subject do
        filter.replace_text_nodes_matching(User.reference_pattern) do |content|
          content
        end
      end

      it { is_expected.to iterate_per_second(iterations) }
    end

    describe 'with different input and output HTML' do
      benchmark_subject do
        filter.replace_text_nodes_matching(User.reference_pattern) do |content|
          '@eve'
        end
      end

      it { is_expected.to iterate_per_second(iterations) }
    end
  end
end
