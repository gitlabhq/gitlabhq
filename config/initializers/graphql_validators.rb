# frozen_string_literal: true

GraphQL::Schema::Validator.install(:mutually_exclusive, Gitlab::Graphql::Validators::MutuallyExclusiveValidator)
GraphQL::Schema::Validator.install(:exactly_one_of, Gitlab::Graphql::Validators::ExactlyOneOfValidator)
