# frozen_string_literal: true

require 'fast_spec_helper'
require 'haml_lint'
require 'haml_lint/spec'
require 'rspec-parameterized'

require_relative '../../../haml_lint/linter/inline_javascript'

RSpec.describe HamlLint::Linter::InlineJavaScript, :uses_fast_spec_helper_but_runs_slow do # rubocop:disable RSpec/SpecFilePathFormat
  using RSpec::Parameterized::TableSyntax

  include_context 'linter'

  let(:message) { described_class::MSG }

  where(:haml, :should_report) do
    '%script'     | true
    '%javascript' | false
    ':javascript' | true
    ':markdown'   | false
  end

  with_them do
    if params[:should_report]
      it { is_expected.to report_lint message: message }
    else
      it { is_expected.not_to report_lint }
    end
  end
end
