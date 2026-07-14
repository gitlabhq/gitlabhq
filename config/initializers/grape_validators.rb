# frozen_string_literal: true

# Grape auto-registers each validator via an `inherited` hook the moment its
# class is loaded, deriving the short name from the class name. We only need to
# ensure every custom validator class is loaded; referencing the constant makes
# Zeitwerk load it (autoload paths are not eager-loaded in development/test).
# `Grape::Validations.register_validator` is removed in Grape 3.x, so we rely on
# auto-registration instead of calling it.
[
  ::API::Validations::Validators::Absence,
  ::API::Validations::Validators::FilePath,
  ::API::Validations::Validators::GitRef,
  ::API::Validations::Validators::GitSha,
  ::API::Validations::Validators::IntegerOrCustomValue,
  ::API::Validations::Validators::IntegerNoneAny,
  ::API::Validations::Validators::ArrayNoneAny,
  ::API::Validations::Validators::CheckAssigneesCount,
  ::API::Validations::Validators::UntrustedRegexp,
  ::API::Validations::Validators::EmailOrEmailList,
  ::API::Validations::Validators::ProjectPortable,
  ::API::Validations::Validators::BulkImports::DestinationNamespacePath,
  ::API::Validations::Validators::BulkImports::DestinationSlugPath,
  ::API::Validations::Validators::BulkImports::SourceFullPath,
  ::API::Validations::Validators::Limit
].each(&:name)
