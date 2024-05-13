# frozen_string_literal: true

GraphQL::Schema::Validator.install(:mutually_exclusive, Gitlab::Graphql::Validators::MutuallyExclusiveValidator)
