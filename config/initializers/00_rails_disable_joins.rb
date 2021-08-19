# frozen_string_literal: true

# Backported from Rails 7.0
# Initial support for has_many :through was implemented in https://github.com/rails/rails/pull/41937
# Support for has_one :through was implemented in https://github.com/rails/rails/pull/42079
raise 'DisableJoins patch is only to be used with versions of Rails < 7.0' unless Rails::VERSION::MAJOR < 7

ActiveRecord::Associations::Association.prepend(GemExtensions::ActiveRecord::Association)
# Temporarily allow :disable_joins to accept a lambda argument, to control rollout with feature flags
ActiveRecord::Associations::Association.prepend(GemExtensions::ActiveRecord::ConfigurableDisableJoins)
ActiveRecord::Associations::Builder::HasOne.prepend(GemExtensions::ActiveRecord::Associations::Builder::HasOne)
ActiveRecord::Associations::Builder::HasMany.prepend(GemExtensions::ActiveRecord::Associations::Builder::HasMany)
ActiveRecord::Associations::HasOneThroughAssociation.prepend(GemExtensions::ActiveRecord::Associations::HasOneThroughAssociation)
ActiveRecord::Associations::HasManyThroughAssociation.prepend(GemExtensions::ActiveRecord::Associations::HasManyThroughAssociation)
ActiveRecord::Associations::Preloader::ThroughAssociation.prepend(GemExtensions::ActiveRecord::Associations::Preloader::ThroughAssociation)
ActiveRecord::Base.extend(GemExtensions::ActiveRecord::DelegateCache)
