import { __, s__ } from '~/locale';

export const DRAWER_CONTAINER_CLASS = '.content-wrapper';

export const JOB_TEMPLATE = {
  name: '',
  stage: '',
  script: '',
  tags: [],
  image: {
    name: '',
    entrypoint: [''],
  },
  services: [
    {
      name: '',
      entrypoint: [''],
    },
  ],
  artifacts: {
    paths: [''],
    exclude: [''],
  },
  cache: {
    paths: [''],
    key: '',
  },
};

export const i18n = {
  ADD_JOB: s__('JobAssistant|Add job'),
  SCRIPT: s__('JobAssistant|Script'),
  JOB_NAME: s__('JobAssistant|Job name'),
  JOB_SETUP: s__('JobAssistant|Job Setup'),
  STAGE: s__('JobAssistant|Stage (optional)'),
  TAGS: s__('JobAssistant|Tags (optional)'),
  IMAGE: s__('JobAssistant|Image'),
  IMAGE_NAME: s__('JobAssistant|Image name (optional)'),
  IMAGE_ENTRYPOINT: s__('JobAssistant|Image entrypoint (optional)'),
  THIS_FIELD_IS_REQUIRED: __('This field is required'),
};
