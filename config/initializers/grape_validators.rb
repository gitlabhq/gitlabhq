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
# TODO Delete this validator along with the packages_conan_allow_empty_username_channel feature flag
# # https://gitlab.com/gitlab-org/gitlab/-/issues/346006
Grape::Validations.register_validator('packages_conan_user_channel', ::API::Validations::Validators::PackagesConanUserChannel)
