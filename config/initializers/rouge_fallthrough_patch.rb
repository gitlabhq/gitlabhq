# frozen_string_literal: true

# Rouge raises Fallthrough for control flow, up to several times per identifier. Capturing a
# backtrace on each raise is expensive at Rails request stack depths, so raise it without one.
module RougeFallthroughPatch
  def fallthrough!
    raise Rouge::RegexLexer::Fallthrough, nil, []
  end
end

# Rouge::RegexLexer.prepend is Rouge's state DSL, so call Module#prepend directly.
Module.instance_method(:prepend).bind_call(Rouge::RegexLexer, RougeFallthroughPatch)
