# Taken from http://www.rubydoc.info/github/rmosolgo/graphql-ruby/GraphQL/ScalarType
Types::TimeType = GraphQL::ScalarType.define do
  name 'Time'
  description 'Time since epoch in fractional seconds'

  coerce_input ->(value, ctx) { Time.at(Float(value)) }
  coerce_result ->(value, ctx) { value.to_f }
end
