import { formValidators } from '@gitlab/ui/dist/utils';
import { s__ } from '~/locale';

export const FORM_FIELD_NAME = 'name';
export const FORM_FIELD_ID = 'id';
export const FORM_FIELD_PATH = 'path';

export const FORM_FIELD_PATH_VALIDATORS = [
  formValidators.required(s__('Organization|Organization URL is required.')),
  formValidators.factory(
    s__('Organization|Organization URL is too short (minimum is 2 characters).'),
    (val) => val.length >= 2,
  ),
];
