# frozen_string_literal: true

Grape::Validations.register_validator(:absence, ::API::Validations::Validators::Absence)
Grape::Validations.register_validator(:file_path, ::API::Validations::Validators::FilePath)
Grape::Validations.register_validator(:git_ref, ::API::Validations::Validators::GitRef)
Grape::Validations.register_validator(:git_sha, ::API::Validations::Validators::GitSha)
Grape::Validations.register_validator(:integer_none_any, ::API::Validations::Validators::IntegerNoneAny)
Grape::Validations.register_validator(:array_none_any, ::API::Validations::Validators::ArrayNoneAny)
Grape::Validations.register_validator(:check_assignees_count, ::API::Validations::Validators::CheckAssigneesCount)
Grape::Validations.register_validator(:untrusted_regexp, ::API::Validations::Validators::UntrustedRegexp)
Grape::Validations.register_validator(:email_or_email_list, ::API::Validations::Validators::EmailOrEmailList)
Grape::Validations.register_validator(:iteration_id, ::API::Validations::Validators::IntegerOrCustomValue)
Grape::Validations.register_validator(:project_portable, ::API::Validations::Validators::ProjectPortable)
Grape::Validations.register_validator(:destination_namespace_path,
  ::API::Validations::Validators::BulkImports::DestinationNamespacePath)
Grape::Validations.register_validator(:destination_slug_path,
  ::API::Validations::Validators::BulkImports::DestinationSlugPath)
Grape::Validations.register_validator(:source_full_path, ::API::Validations::Validators::BulkImports::SourceFullPath)
Grape::Validations.register_validator(:limit, ::API::Validations::Validators::Limit)
