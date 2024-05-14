import { formValidators } from '@gitlab/ui/dist/utils';
import { s__, sprintf } from '~/locale';

export const FORM_FIELD_NAME = 'name';
export const FORM_FIELD_ID = 'id';
export const FORM_FIELD_DESCRIPTION = 'description';

// Match backend validation - https://gitlab.com/gitlab-org/gitlab/-/blob/a6a6bab796dc1f317fae4b65cff7da08e79e3345/app/models/project.rb#L572
export const MAX_DESCRIPTION_COUNT = 2000;

export const FORM_FIELD_DESCRIPTION_VALIDATORS = [
  formValidators.factory(
    sprintf(
      s__('ProjectsNewEdit|Project description is too long (maximum is %{count} characters).'),
      { count: MAX_DESCRIPTION_COUNT },
    ),
    (val) => val.length <= MAX_DESCRIPTION_COUNT,
  ),
];
