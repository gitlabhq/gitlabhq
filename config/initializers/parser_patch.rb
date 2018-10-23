# frozen_literal_string: true

# This works around unnecessary static-analysis warnings that will be
# fixed via https://github.com/whitequark/parser/pull/528.
module Parser
  class << self
    def warn_syntax_deviation(feature, version)
      return if ['2.3.8', '2.4.5', '2.5.3'].include?(version)

      warn "warning: parser/current is loading #{feature}, which recognizes"
      warn "warning: #{version}-compliant syntax, but you are running #{RUBY_VERSION}."
      warn "warning: please see https://github.com/whitequark/parser#compatibility-with-ruby-mri."
    end
  end
end
