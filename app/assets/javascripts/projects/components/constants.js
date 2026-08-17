import { formValidators } from '@gitlab/ui/src/utils';
import { s__, sprintf } from '~/locale';

export const FORM_FIELD_NAME = 'name';
export const FORM_FIELD_ID = 'id';
export const FORM_FIELD_DESCRIPTION = 'description';

// Match backend validation - Project::MAX_DESCRIPTION_LENGTH in app/models/project.rb
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
